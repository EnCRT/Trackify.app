import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'lap.dart';

import '../utils/time_utils.dart';

class Session {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final String locationName;
  final int durationMillis;
  final double totalDistanceMeters;
  final DateTime importDate;
  final List<LatLng> routePoints;
  final List<double> routeSpeeds; // Speed in km/h for each route point
  final List<DateTime> routeTimestamps; // Actual GPS timestamps for each point
  final List<Lap> laps;
  final List<List<LatLng>> sectorGates; // Each gate = [p1, p2] line segment

  Session({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.importDate,
    required this.locationName,
    required this.durationMillis,
    required this.totalDistanceMeters,
    required this.routePoints,
    required this.routeSpeeds,
    this.routeTimestamps = const [],
    this.laps = const [],
    this.sectorGates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'importDate': importDate.toIso8601String(),
      'locationName': locationName,
      'durationMillis': durationMillis,
      'totalDistanceMeters': totalDistanceMeters,
      'routePointsJson': jsonEncode(
        routePoints
            .map((ll) => {'lat': ll.latitude, 'lng': ll.longitude})
            .toList(),
      ),
      'routeSpeedsJson': jsonEncode(routeSpeeds),
      'routeTimestampsJson': jsonEncode(
        routeTimestamps.map((t) => t.toIso8601String()).toList(),
      ),
      'lapsJson': jsonEncode(laps.map((l) => l.toMap()).toList()),
      'sectorGatesJson': jsonEncode(
        sectorGates
            .map(
              (gate) => gate
                  .map((ll) => {'lat': ll.latitude, 'lng': ll.longitude})
                  .toList(),
            )
            .toList(),
      ),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    List<LatLng> points = [];
    if (map['routePointsJson'] != null) {
      final List<dynamic> jsonList = jsonDecode(map['routePointsJson']);
      points = jsonList
          .map((e) => LatLng(e['lat'] as double, e['lng'] as double))
          .toList();
    }

    List<double> speeds = [];
    if (map['routeSpeedsJson'] != null) {
      final List<dynamic> speedsJsonList = jsonDecode(map['routeSpeedsJson']);
      speeds = speedsJsonList.map((e) => (e as num).toDouble()).toList();
    }

    List<DateTime> timestamps = [];
    if (map['routeTimestampsJson'] != null) {
      final List<dynamic> tsJsonList = jsonDecode(map['routeTimestampsJson']);
      timestamps = tsJsonList.map((e) => DateTime.parse(e as String)).toList();
    }

    List<Lap> laps = [];
    if (map['lapsJson'] != null) {
      final List<dynamic> lapsJsonList = jsonDecode(map['lapsJson']);
      laps = lapsJsonList.map((e) => Lap.fromMap(e)).toList();
    }

    List<List<LatLng>> sectorGates = [];
    if (map['sectorGatesJson'] != null) {
      final List<dynamic> gatesJsonList = jsonDecode(map['sectorGatesJson']);
      sectorGates = gatesJsonList
          .map(
            (gate) => (gate as List<dynamic>)
                .map((e) => LatLng(e['lat'] as double, e['lng'] as double))
                .toList(),
          )
          .toList();
    }

    return Session(
      id: map['id'],
      vehicleId: map['vehicleId'],
      date: DateTime.parse(map['date']),
      importDate: map['importDate'] != null
          ? DateTime.parse(map['importDate'])
          : DateTime.parse(map['date']),
      locationName: map['locationName'],
      durationMillis: (map['durationMillis'] as int).abs(),
      totalDistanceMeters: map['totalDistanceMeters'],
      routePoints: points,
      routeSpeeds: speeds,
      routeTimestamps: timestamps,
      laps: laps,
      sectorGates: sectorGates,
    );
  }

  String get formattedDuration =>
      TimeUtils.formatDurationConcise(durationMillis);
}
