import 'package:latlong2/latlong.dart';
import '../models/lap.dart';

class LapCalculatorService {
  static const double gateWidthMeters = 30.0;
  static const Distance distanceHelper = Distance();

  /// Minimum distance (meters) from last crossing before a new one can be detected.
  /// Prevents double-triggering when the route oscillates near a gate.
  static const double debounceDistanceMeters = 15.0;

  /// Calculates laps and sectors for a session based on provided gate points.
  /// The first point in [sectorPoints] is treated as the Start/Finish line.
  /// [routeTimestamps] contains real GPS timestamps for accurate timing.
  static List<Lap> calculateLaps({
    required List<LatLng> routePoints,
    required List<double> routeSpeeds,
    required List<List<LatLng>> sectorGates,
    List<DateTime> routeTimestamps = const [],
  }) {
    if (routePoints.isEmpty || sectorGates.isEmpty) return [];

    // 1. Build millisecond timestamps from real GPS times or reconstruct as fallback
    final List<int> timestamps =
        routeTimestamps.isNotEmpty &&
            routeTimestamps.length == routePoints.length
        ? _timestampsFromDateTimes(routeTimestamps)
        : _reconstructTimestamps(routePoints, routeSpeeds);

    // 2. Convert user-drawn gate lines to GateLine objects
    final List<GateLine> gates = sectorGates
        .where((g) => g.length == 2)
        .map((g) => GateLine(p1: g[0], p2: g[1]))
        .toList();
    if (gates.isEmpty) return [];

    final List<Crossing> crossings = [];

    // 3. Detect all crossings with interpolation and distance-based debounce
    LatLng? lastCrossingPoint;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];

      for (int gIdx = 0; gIdx < gates.length; gIdx++) {
        final gate = gates[gIdx];
        if (_segmentsIntersect(p1, p2, gate.p1, gate.p2)) {
          // Calculate exact intersection point for debounce
          double t = _getIntersectionFraction(p1, p2, gate.p1, gate.p2);
          t = t.clamp(0.0, 1.0);

          final intersectionLat = p1.latitude + t * (p2.latitude - p1.latitude);
          final intersectionLng =
              p1.longitude + t * (p2.longitude - p1.longitude);
          final intersectionPoint = LatLng(intersectionLat, intersectionLng);

          // Distance-based debounce: skip if too close to last crossing
          if (lastCrossingPoint != null) {
            final distFromLast = distanceHelper.as(
              LengthUnit.Meter,
              lastCrossingPoint,
              intersectionPoint,
            );
            if (distFromLast < debounceDistanceMeters) {
              continue;
            }
          }

          // Interpolate exact time
          double interpolatedTime =
              timestamps[i] + t * (timestamps[i + 1] - timestamps[i]);

          crossings.add(
            Crossing(
              pointIndex: i,
              gateIndex: gIdx,
              timeMillis: interpolatedTime.toInt(),
            ),
          );

          lastCrossingPoint = intersectionPoint;
          break; // One gate per segment
        }
      }
    }

    if (crossings.isEmpty) return [];

    // 4. Group crossings into Laps
    final List<Lap> laps = [];
    int lapCount = 1;

    // Find the first Start/Finish crossing (gate 0)
    int firstStartIdx = crossings.indexWhere((c) => c.gateIndex == 0);
    if (firstStartIdx == -1) return [];

    for (int i = firstStartIdx; i < crossings.length; i++) {
      final startCrossing = crossings[i];
      if (startCrossing.gateIndex != 0) continue;

      // Find next Start/Finish crossing (completes one lap)
      int nextStartCrossingIdx = -1;
      for (int j = i + 1; j < crossings.length; j++) {
        if (crossings[j].gateIndex == 0) {
          nextStartCrossingIdx = j;
          break;
        }
      }

      if (nextStartCrossingIdx == -1) break;

      final endCrossing = crossings[nextStartCrossingIdx];

      // 5. Build sectors: each sector is the time between consecutive crossings
      //    including the final sector from last intermediate gate to the finish line
      final List<SectorData> sectors = [];
      int prevCrossingTime = startCrossing.timeMillis;

      // Intermediate gate crossings (between start and next start)
      for (int k = i + 1; k < nextStartCrossingIdx; k++) {
        final sectorCrossing = crossings[k];
        sectors.add(
          SectorData(
            sectorIndex: sectors.length + 1,
            durationMillis: sectorCrossing.timeMillis - prevCrossingTime,
            crossingPointIndex: sectorCrossing.pointIndex,
          ),
        );
        prevCrossingTime = sectorCrossing.timeMillis;
      }

      // Last sector: from last intermediate gate (or start) to finish line
      sectors.add(
        SectorData(
          sectorIndex: sectors.length + 1,
          durationMillis: endCrossing.timeMillis - prevCrossingTime,
          crossingPointIndex: endCrossing.pointIndex,
        ),
      );

      laps.add(
        Lap(
          number: lapCount++,
          durationMillis: endCrossing.timeMillis - startCrossing.timeMillis,
          startPointIndex: startCrossing.pointIndex,
          endPointIndex: endCrossing.pointIndex,
          sectors: sectors,
        ),
      );

      i = nextStartCrossingIdx - 1;
    }

    return laps;
  }

  /// Convert real DateTimes to relative milliseconds from the first timestamp.
  static List<int> _timestampsFromDateTimes(List<DateTime> times) {
    if (times.isEmpty) return [];
    final base = times.first;
    return times.map((t) => t.difference(base).inMilliseconds).toList();
  }

  /// Fallback: reconstruct timestamps from speed and distance.
  /// Used only when real timestamps are unavailable.
  static List<int> _reconstructTimestamps(
    List<LatLng> points,
    List<double> speeds,
  ) {
    final List<int> timestamps = [0];
    double currentMs = 0;

    for (int i = 0; i < points.length - 1; i++) {
      double dist = distanceHelper.as(
        LengthUnit.Meter,
        points[i],
        points[i + 1],
      );
      double avgSpeedKmh = (speeds[i] + speeds[i + 1]) / 2;
      if (avgSpeedKmh < 1.0) avgSpeedKmh = 1.0;

      // Convert: time(ms) = distance(m) / speed(m/s) * 1000
      // speed(m/s) = speed(km/h) * 1000 / 3600
      double speedMs = avgSpeedKmh * 1000.0 / 3600.0;
      double deltaMs = (dist / speedMs) * 1000.0;
      currentMs += deltaMs;
      timestamps.add(currentMs.toInt());
    }
    return timestamps;
  }

  /// Compute the parametric fraction t ∈ [0,1] along segment AB
  /// where it intersects segment CD.
  static double _getIntersectionFraction(
    LatLng a,
    LatLng b,
    LatLng c,
    LatLng d,
  ) {
    // Using the standard line-line intersection formula:
    // t = ((c - a) × (d - c)) / ((b - a) × (d - c))
    // where × is the 2D cross product
    double bax = b.longitude - a.longitude;
    double bay = b.latitude - a.latitude;
    double dcx = d.longitude - c.longitude;
    double dcy = d.latitude - c.latitude;
    double cax = c.longitude - a.longitude;
    double cay = c.latitude - a.latitude;

    double det = bax * dcy - bay * dcx;
    if (det.abs() < 1e-15) return 0.5;

    double t = (cax * dcy - cay * dcx) / det;
    return t;
  }

  /// Checks whether segments AB and CD intersect using the standard
  /// parametric approach: both t and u must be in (0, 1).
  static bool _segmentsIntersect(LatLng a, LatLng b, LatLng c, LatLng d) {
    double bax = b.longitude - a.longitude;
    double bay = b.latitude - a.latitude;
    double dcx = d.longitude - c.longitude;
    double dcy = d.latitude - c.latitude;
    double cax = c.longitude - a.longitude;
    double cay = c.latitude - a.latitude;

    double det = bax * dcy - bay * dcx;
    if (det.abs() < 1e-15) return false;

    double t = (cax * dcy - cay * dcx) / det;
    double u = (cax * bay - cay * bax) / det;

    return (0 < t && t < 1) && (0 < u && u < 1);
  }
}

class GateLine {
  final LatLng p1;
  final LatLng p2;
  GateLine({required this.p1, required this.p2});
}

class Crossing {
  final int pointIndex;
  final int gateIndex;
  final int timeMillis;
  Crossing({
    required this.pointIndex,
    required this.gateIndex,
    required this.timeMillis,
  });
}
