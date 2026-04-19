import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/session.dart';
import '../models/vehicle.dart';
import '../utils/time_utils.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  int _selectedLapIndex = 0; // 0 = Full Session (or all valid laps)
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.locationName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final updatedSession = Session(
      id: widget.session.id,
      vehicleId: widget.session.vehicleId,
      date: widget.session.date,
      importDate: widget.session.importDate,
      locationName: newName,
      durationMillis: widget.session.durationMillis,
      totalDistanceMeters: widget.session.totalDistanceMeters,
      routePoints: widget.session.routePoints,
      routeSpeeds: widget.session.routeSpeeds,
      routeTimestamps: widget.session.routeTimestamps,
      laps: widget.session.laps,
      sectorGates: widget.session.sectorGates,
    );

    await context.read<SessionProvider>().updateSession(updatedSession);

    if (mounted) {
      setState(() {
        _isEditingName = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.sessionNameUpdated),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find the latest session data from the provider to ensure title updates
    final sessionProvider = context.watch<SessionProvider>();
    final session = sessionProvider.sessions.firstWhere(
      (s) => s.id == widget.session.id,
      orElse: () => widget.session,
    );

    final vehicleProvider = context.watch<VehicleProvider>();
    final sessionVehicle = vehicleProvider.vehicles.firstWhere(
      (v) => v.id == session.vehicleId,
      orElse: () => Vehicle(brand: 'Unknown', model: 'Vehicle', year: 0),
    );
    final vehicleName = sessionVehicle.displayName;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: _isEditingName
              ? TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterSessionName,
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                )
              : Text(session.locationName),
          actions: [
            if (_isEditingName)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _saveName,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => setState(() => _isEditingName = true),
              ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              onPressed: () => _confirmDelete(context),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.mapAndStats),
              Tab(text: AppLocalizations.of(context)!.sectorsAnalysis),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          physics:
              const NeverScrollableScrollPhysics(), // Prevent conflicts with map panning
          children: [
            _buildMapAndStats(context, session, vehicleName),
            _SectorAnalysisTable(session: session),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteSession),
          content: Text(AppLocalizations.of(context)!.deleteSessionConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<SessionProvider>().deleteSession(widget.session.id!);
      await context.read<UserProvider>().refreshGlobalStats();
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sessionDeleted),
          ),
        );
      }
    }
  }

  Widget _buildLapSelector(Session session) {
    final int lapCount = session.laps.length;
    if (lapCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _selectedLapIndex > 0
                ? () => setState(() => _selectedLapIndex--)
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedLapIndex == 0
                    ? AppLocalizations.of(context)!.allLaps
                    : AppLocalizations.of(context)!.lapIndex(_selectedLapIndex),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepOrange,
                ),
              ),
              if (_selectedLapIndex > 0)
                Text(
                  session.laps[_selectedLapIndex - 1].formattedDuration,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedLapIndex < lapCount
                ? () => setState(() => _selectedLapIndex++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMapAndStats(
    BuildContext context,
    Session session,
    String vehicleName,
  ) {
    final laps = session.laps;

    // Find best lap
    int? bestLapIdx;
    if (laps.isNotEmpty) {
      int bestTime = laps[0].durationMillis;
      bestLapIdx = 0;
      for (int i = 1; i < laps.length; i++) {
        if (laps[i].durationMillis < bestTime) {
          bestTime = laps[i].durationMillis;
          bestLapIdx = i;
        }
      }
    }

    // Calculate total track time (sum of all lap times)
    int totalTrackTimeMillis = 0;
    for (var lap in laps) {
      totalTrackTimeMillis += lap.durationMillis;
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vehicleName.isNotEmpty && vehicleName != '0 Unknown Vehicle')
                Text(
                  vehicleName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              const SizedBox(height: 0),
              Text(
                DateFormat(
                  'EEEE, MMMM d, yyyy - h:mm a',
                ).format(session.date),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCircle(
                    icon: Icons.straighten,
                    label: AppLocalizations.of(context)!.distance,
                    value:
                        '${(session.totalDistanceMeters / 1000).toStringAsFixed(2)} km',
                    color: Colors.lightGreen,
                  ),
                  _StatCircle(
                    icon: Icons.timer,
                    label: AppLocalizations.of(context)!.totalTime,
                    value: _formatDuration(totalTrackTimeMillis),
                    color: Colors.deepOrange,
                  ),
                  if (bestLapIdx != null)
                    _StatCircle(
                      icon: Icons.emoji_events,
                      label: AppLocalizations.of(context)!.bestLap,
                      value: laps[bestLapIdx].formattedDuration,
                      color: Colors.purple,
                    ),
                ],
              ),
              if (laps.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.lapsCompleted(laps.length),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildLapSelector(session),
        Expanded(
          child: _SessionMapWithZoom(
            session: session,
            selectedLapIndex: _selectedLapIndex,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int ms) => TimeUtils.formatDuration(ms);
}

class _StatCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCircle({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        // Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}

class _SessionMapWithZoom extends StatefulWidget {
  final Session session;
  final int selectedLapIndex;

  const _SessionMapWithZoom({
    required this.session,
    required this.selectedLapIndex,
  });

  @override
  State<_SessionMapWithZoom> createState() => _SessionMapWithZoomState();
}

class _SessionMapWithZoomState extends State<_SessionMapWithZoom> {
  final MapController _mapController = MapController();

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  Color _getSpeedColor(double speed, double minSpeed, double maxSpeed) {
    if (maxSpeed <= minSpeed) return Colors.green;
    double t = ((speed - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);

    // Multi-stop gradient: red(slow) -> orange -> yellow -> green(fast)
    if (t <= 0.33) {
      double s = t / 0.33;
      return Color.lerp(
        const Color(0xFFE53935), // Red
        const Color(0xFFFB8C00), // Orange
        s,
      )!;
    } else if (t <= 0.66) {
      double s = (t - 0.33) / 0.33;
      return Color.lerp(
        const Color(0xFFFB8C00), // Orange
        const Color(0xFFFFEB3B), // Yellow
        s,
      )!;
    } else {
      double s = (t - 0.66) / 0.34;
      return Color.lerp(
        const Color(0xFFFFEB3B), // Yellow
        const Color(0xFF43A047), // Green
        s,
      )!;
    }
  }

  List<Polyline> _buildHeatmapPolylines() {
    List<LatLng> route = widget.session.routePoints;
    List<double> speeds = widget.session.routeSpeeds;

    // Filter by lap if needed
    if (widget.selectedLapIndex > 0 && widget.session.laps.isNotEmpty) {
      final lap = widget.session.laps[widget.selectedLapIndex - 1];
      final endIdx = (lap.endPointIndex + 1).clamp(0, route.length);
      route = route.sublist(lap.startPointIndex, endIdx);
      speeds = speeds.sublist(lap.startPointIndex, endIdx);
    } else if (widget.session.laps.isNotEmpty) {
      // Trim to all valid laps (from first lap start to last lap end)
      final firstLap = widget.session.laps.first;
      final lastLap = widget.session.laps.last;
      final endIdx = (lastLap.endPointIndex + 1).clamp(0, route.length);
      route = route.sublist(firstLap.startPointIndex, endIdx);
      speeds = speeds.sublist(firstLap.startPointIndex, endIdx);
    }

    if (speeds.isEmpty || speeds.length != route.length) {
      return [
        Polyline(
          points: route,
          strokeWidth: 4.0,
          color: Colors.blue,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ];
    }

    // Apply moving average smoothing (15-point window for smooth GPS data)
    final int halfWindow = 7;
    List<double> smoothedSpeeds = [];
    for (int i = 0; i < speeds.length; i++) {
      int start = (i - halfWindow).clamp(0, speeds.length - 1);
      int end = (i + halfWindow).clamp(0, speeds.length - 1);
      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += speeds[j];
      }
      smoothedSpeeds.add(sum / (end - start + 1));
    }

    // Compute min/max for color mapping
    double minSpeed = double.infinity;
    double maxSpeed = 0;
    for (final s in smoothedSpeeds) {
      if (s < minSpeed) minSpeed = s;
      if (s > maxSpeed) maxSpeed = s;
    }

    // Filter out points that are too close to each other
    final List<LatLng> filteredPoints = [];
    final List<double> filteredSpeeds = [];
    const distanceHelper = Distance();

    if (route.isNotEmpty) {
      filteredPoints.add(route[0]);
      filteredSpeeds.add(smoothedSpeeds[0]);
      LatLng prev = route[0];
      for (int i = 1; i < route.length; i++) {
        final curr = route[i];
        if (distanceHelper.as(LengthUnit.Meter, prev, curr) > 1.5) {
          filteredPoints.add(curr);
          filteredSpeeds.add(smoothedSpeeds[i]);
          prev = curr;
        }
      }
      if (filteredPoints.length < 2 && route.length > 1) {
        filteredPoints.add(route.last);
        filteredSpeeds.add(smoothedSpeeds.last);
      }
    }

    if (filteredPoints.length < 2) {
      return [
        Polyline(
          points: route,
          strokeWidth: 6.0,
          color: Colors.blue,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ];
    }

    final List<Color> colors = [];
    final List<double> stops = [];
    double totalDist = 0;
    List<double> segmentDistances = [0];

    for (int i = 0; i < filteredPoints.length; i++) {
      colors.add(_getSpeedColor(filteredSpeeds[i], minSpeed, maxSpeed));
      if (i > 0) {
        double d = distanceHelper.as(
          LengthUnit.Meter,
          filteredPoints[i - 1],
          filteredPoints[i],
        );
        totalDist += d;
        segmentDistances.add(totalDist);
      }
    }

    if (totalDist > 0) {
      for (int i = 0; i < segmentDistances.length; i++) {
        stops.add(segmentDistances[i] / totalDist);
      }
    } else {
      for (int i = 0; i < filteredPoints.length; i++) {
        stops.add(i / (filteredPoints.length - 1));
      }
    }

    // Ensure stops are strictly increasing
    for (int i = 1; i < stops.length; i++) {
      if (stops[i] <= stops[i - 1]) {
        stops[i] = stops[i - 1] + 0.000001;
      }
    }
    if (stops.last > 1.0) stops[stops.length - 1] = 1.0;

    return [
      Polyline(
        points: filteredPoints,
        strokeWidth: 3.0,
        gradientColors: colors,
        colorsStop: stops,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.session.routePoints;
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    if (route.isNotEmpty) {
      for (var p in route) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
    }

    final bounds = route.isNotEmpty
        ? LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng))
        : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: bounds != null
                ? CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  )
                : null,
            initialCenter: bounds == null ? const LatLng(0, 0) : bounds.center,
            initialZoom: bounds == null ? 2 : 15,
            cameraConstraint: const CameraConstraint.unconstrained(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            minZoom: 10,
            maxZoom: 20,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.moto_lap_timer',
            ),
            PolylineLayer(
              polylines: [
                ..._buildHeatmapPolylines(),
                // Gate lines
                for (int i = 0; i < widget.session.sectorGates.length; i++)
                  if (widget.session.sectorGates[i].length == 2)
                    Polyline(
                      points: widget.session.sectorGates[i],
                      strokeWidth: 3.0,
                      color: i == 0 ? Colors.green : Colors.orange,
                      strokeCap: StrokeCap.round,
                    ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (int i = 0; i < widget.session.sectorGates.length; i++)
                  if (widget.session.sectorGates[i].length == 2)
                    Marker(
                      point: LatLng(
                        (widget.session.sectorGates[i][0].latitude +
                                widget.session.sectorGates[i][1].latitude) /
                            2,
                        (widget.session.sectorGates[i][0].longitude +
                                widget.session.sectorGates[i][1].longitude) /
                            2,
                      ),
                      width: 36,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: i == 0 ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          i == 0
                              ? AppLocalizations.of(context)!.sfGate
                              : AppLocalizations.of(context)!.sectorGate(i),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
        // Speed legend
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.slow,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEB3B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.mid,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF43A047),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.fast,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomInSession',
                onPressed: _zoomIn,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                child: const Icon(Icons.add, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOutSession',
                onPressed: _zoomOut,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                child: const Icon(Icons.remove, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Sector Analysis Table with Lap Time Column + Delta Mode
// ----------------------------------------------------
class _SectorAnalysisTable extends StatefulWidget {
  final Session session;
  const _SectorAnalysisTable({required this.session});

  @override
  State<_SectorAnalysisTable> createState() => _SectorAnalysisTableState();
}

class _SectorAnalysisTableState extends State<_SectorAnalysisTable> {
  bool _isDeltaMode = false;

  String _formatTime(int ms) => TimeUtils.formatDuration(ms);

  String _formatDelta(int deltaMs) {
    if (deltaMs == 0) return '±0.000';
    final sign = deltaMs > 0 ? '+' : '-';
    // Use formatDuration for the absolute value, but maybe without hours/days if not needed?
    // Actually, delta could be large too.
    return '$sign${TimeUtils.formatDuration(deltaMs.abs())}';
  }

  Widget _buildCell(
    String text, {
    Color? textColor,
    Color? backgroundColor,
    bool isHeader = false,
    bool isBest = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isBest ? Colors.amber.withValues(alpha: 0.15) : null),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader || isBest ? FontWeight.bold : FontWeight.w500,
          color: textColor ?? Colors.black87,
          fontSize: isBest ? 14 : 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laps = widget.session.laps;
    final int numLaps = laps.length;

    if (numLaps == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noLapsDetected,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Find max number of sectors among laps
    int numSectors = 0;
    for (var l in laps) {
      if (l.sectors.length > numSectors) numSectors = l.sectors.length;
    }

    // Find best lap index
    int bestLapIdx = 0;
    for (int i = 1; i < numLaps; i++) {
      if (laps[i].durationMillis < laps[bestLapIdx].durationMillis) {
        bestLapIdx = i;
      }
    }

    // Find best sector times for each sector
    List<int> bestSectorTimes = List.filled(numSectors, 0x7FFFFFFF);
    for (var lap in laps) {
      for (int j = 0; j < lap.sectors.length && j < numSectors; j++) {
        if (lap.sectors[j].durationMillis < bestSectorTimes[j]) {
          bestSectorTimes[j] = lap.sectors[j].durationMillis;
        }
      }
    }

    // Decide whether to transpose: we want fewer columns for mobile readability.
    final bool transpose = numLaps < numSectors;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isDeltaMode = !_isDeltaMode;
        });
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDeltaMode ? Icons.compare_arrows : Icons.timer,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isDeltaMode
                        ? AppLocalizations.of(context)!.sectorAnalysisDeltaMode
                        : AppLocalizations.of(
                            context,
                          )!.sectorAnalysisAbsoluteMode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: transpose
                      ? _buildTransposedTable(
                          numLaps,
                          numSectors,
                          bestLapIdx,
                          bestSectorTimes,
                        )
                      : _buildNormalTable(
                          numLaps,
                          numSectors,
                          bestLapIdx,
                          bestSectorTimes,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalTable(
    int numLaps,
    int numSectors,
    int bestLapIdx,
    List<int> bestSectorTimes,
  ) {
    return DataTable(
      columnSpacing: 20,
      headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
      columns: [
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.lap,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.deepOrange,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.lapTime,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        for (int i = 0; i < numSectors; i++)
          DataColumn(
            label: Text(
              AppLocalizations.of(context)!.sectorGate(i + 1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
      rows: [
        for (int i = 0; i < numLaps; i++)
          DataRow(
            color: i == bestLapIdx
                ? WidgetStateProperty.all(Colors.amber.withValues(alpha: 0.08))
                : null,
            cells: [
              DataCell(
                _buildCell(
                  i == bestLapIdx
                      ? '🏆 ${AppLocalizations.of(context)!.lapIndex(i + 1)}'
                      : AppLocalizations.of(context)!.lapIndex(i + 1),
                  isHeader: true,
                  isBest: i == bestLapIdx,
                ),
              ),
              _buildLapTimeCell(i, bestLapIdx),
              for (int j = 0; j < numSectors; j++)
                _buildSectorCell(i, j, bestLapIdx, bestSectorTimes),
            ],
          ),
      ],
    );
  }

  Widget _buildTransposedTable(
    int numLaps,
    int numSectors,
    int bestLapIdx,
    List<int> bestSectorTimes,
  ) {
    return DataTable(
      columnSpacing: 20,
      headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
      columns: [
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.sector,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.deepOrange,
            ),
          ),
        ),
        for (int i = 0; i < numLaps; i++)
          DataColumn(
            label: Text(
              i == bestLapIdx
                  ? '🏆 ${AppLocalizations.of(context)!.lapShort(i + 1)}'
                  : AppLocalizations.of(context)!.lapShort(i + 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: i == bestLapIdx ? Colors.amber[800] : Colors.deepPurple,
              ),
            ),
          ),
      ],
      rows: [
        // Lap Time Row
        DataRow(
          cells: [
            DataCell(
              _buildCell(
                AppLocalizations.of(context)!.totalTime,
                isHeader: true,
              ),
            ),
            for (int i = 0; i < numLaps; i++) _buildLapTimeCell(i, bestLapIdx),
          ],
        ),
        // Sector Rows
        for (int j = 0; j < numSectors; j++)
          DataRow(
            cells: [
              DataCell(
                _buildCell(
                  AppLocalizations.of(context)!.sectorGate(j + 1),
                  isHeader: true,
                ),
              ),
              for (int i = 0; i < numLaps; i++)
                _buildSectorCell(i, j, bestLapIdx, bestSectorTimes),
            ],
          ),
      ],
    );
  }

  DataCell _buildLapTimeCell(int i, int bestLapIdx) {
    final laps = widget.session.laps;
    if (!_isDeltaMode || i == bestLapIdx) {
      return DataCell(
        _buildCell(
          _formatTime(laps[i].durationMillis),
          textColor: Colors.deepPurple,
          isBest: i == bestLapIdx,
        ),
      );
    } else {
      final delta = laps[i].durationMillis - laps[bestLapIdx].durationMillis;
      return DataCell(
        _buildCell(
          _formatDelta(delta),
          textColor: Colors.white,
          backgroundColor: delta > 0 ? Colors.red[400] : Colors.green[400],
        ),
      );
    }
  }

  DataCell _buildSectorCell(
    int i,
    int j,
    int bestLapIdx,
    List<int> bestSectorTimes,
  ) {
    final laps = widget.session.laps;
    if (j >= laps[i].sectors.length) {
      return DataCell(_buildCell("-"));
    }
    final currentSectorTime = laps[i].sectors[j].durationMillis;
    final isBestOverall = currentSectorTime == bestSectorTimes[j];

    if (!_isDeltaMode) {
      return DataCell(
        _buildCell(
          _formatTime(currentSectorTime),
          textColor: isBestOverall ? Colors.purple : null,
          isBest: isBestOverall,
        ),
      );
    } else {
      if (j >= laps[bestLapIdx].sectors.length) {
        return DataCell(_buildCell("-"));
      }
      if (i == bestLapIdx) {
        return DataCell(
          _buildCell(_formatTime(currentSectorTime), isBest: true),
        );
      }
      final bestLapSectorTime = laps[bestLapIdx].sectors[j].durationMillis;
      final delta = currentSectorTime - bestLapSectorTime;
      return DataCell(
        _buildCell(
          _formatDelta(delta),
          textColor: delta == 0 ? Colors.black87 : Colors.white,
          backgroundColor: delta > 0
              ? Colors.red[400]
              : (delta < 0 ? Colors.green[400] : null),
        ),
      );
    }
  }
}
