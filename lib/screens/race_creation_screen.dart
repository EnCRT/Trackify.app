import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/lap_calculator_service.dart';

class RaceCreationScreen extends StatefulWidget {
  final Session parsedSession;

  const RaceCreationScreen({super.key, required this.parsedSession});

  @override
  State<RaceCreationScreen> createState() => _RaceCreationScreenState();
}

class _RaceCreationScreenState extends State<RaceCreationScreen> {
  late MapController _mapController;
  late TextEditingController _nameController;

  /// Completed gate lines (each gate = [point1, point2])
  final List<List<LatLng>> _gates = [];

  /// First tap of a gate being drawn (null = waiting for first tap)
  LatLng? _pendingPoint;

  int? _selectedVehicleId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _nameController = TextEditingController(
      text: widget.parsedSession.locationName,
    );
    _selectedVehicleId = widget.parsedSession.vehicleId;
    _selectedDate = widget.parsedSession.date;
    _selectedTime = TimeOfDay.fromDateTime(widget.parsedSession.date);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vehicleProvider = context.read<VehicleProvider>();
        if (_selectedVehicleId == 0 || _selectedVehicleId == null) {
          if (vehicleProvider.currentVehicle != null) {
            setState(() {
              _selectedVehicleId = vehicleProvider.currentVehicle!.id;
            });
          } else if (vehicleProvider.vehicles.isNotEmpty) {
            setState(() {
              _selectedVehicleId = vehicleProvider.vehicles.first.id;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

  void _onMapTap(LatLng point) {
    setState(() {
      if (_pendingPoint == null) {
        // First tap — start drawing a gate line
        _pendingPoint = point;
      } else {
        // Second tap — complete the gate line
        if (_gates.length < 5) {
          _gates.add([_pendingPoint!, point]);
          _pendingPoint = null;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.maxGatesAllowed),
            ),
          );
          _pendingPoint = null;
        }
      }
    });
  }

  void _undoLast() {
    setState(() {
      if (_pendingPoint != null) {
        // Cancel pending first tap
        _pendingPoint = null;
      } else if (_gates.isNotEmpty) {
        // Remove last completed gate
        _gates.removeLast();
      }
    });
  }

  void _clearAll() {
    setState(() {
      _gates.clear();
      _pendingPoint = null;
    });
  }

  Color _getSpeedColor(double speed, double minSpeed, double maxSpeed) {
    if (maxSpeed <= minSpeed) return Colors.green;
    double t = ((speed - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);

    if (t <= 0.33) {
      double s = t / 0.33;
      return Color.lerp(const Color(0xFFE53935), const Color(0xFFFB8C00), s)!;
    } else if (t <= 0.66) {
      double s = (t - 0.33) / 0.33;
      return Color.lerp(const Color(0xFFFB8C00), const Color(0xFFFFEB3B), s)!;
    } else {
      double s = (t - 0.66) / 0.34;
      return Color.lerp(const Color(0xFFFFEB3B), const Color(0xFF43A047), s)!;
    }
  }

  List<Polyline> _buildHeatmapPolylines() {
    final route = widget.parsedSession.routePoints;
    final speeds = widget.parsedSession.routeSpeeds;

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

    double minSpeed = double.infinity;
    double maxSpeed = 0;
    for (final s in smoothedSpeeds) {
      if (s < minSpeed) minSpeed = s;
      if (s > maxSpeed) maxSpeed = s;
    }

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

    for (int i = 1; i < stops.length; i++) {
      if (stops[i] <= stops[i - 1]) {
        stops[i] = stops[i - 1] + 0.000001;
      }
    }
    if (stops.last > 1.0) stops[stops.length - 1] = 1.0;

    return [
      Polyline(
        points: filteredPoints,
        strokeWidth: 6.0,
        gradientColors: colors,
        colorsStop: stops,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ];
  }

  /// Build polylines for completed gate lines + pending point indicator
  List<Polyline> _buildGatePolylines() {
    final List<Polyline> lines = [];

    for (int i = 0; i < _gates.length; i++) {
      final gate = _gates[i];
      lines.add(
        Polyline(
          points: gate,
          strokeWidth: 4.0,
          color: i == 0 ? Colors.green : Colors.orange,
          strokeCap: StrokeCap.round,
        ),
      );
    }

    return lines;
  }

  /// Build markers for gate endpoints and pending point
  List<Marker> _buildGateMarkers() {
    final List<Marker> markers = [];

    // Completed gate endpoints
    for (int i = 0; i < _gates.length; i++) {
      final gate = _gates[i];
      final color = i == 0 ? Colors.green : Colors.orange;
      final label = i == 0
          ? AppLocalizations.of(context)!.sfGate
          : AppLocalizations.of(context)!.sectorGate(i);

      // Midpoint label
      final midLat = (gate[0].latitude + gate[1].latitude) / 2;
      final midLng = (gate[0].longitude + gate[1].longitude) / 2;
      markers.add(
        Marker(
          point: LatLng(midLat, midLng),
          width: 40,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

      // Endpoint dots
      for (final point in gate) {
        markers.add(
          Marker(
            point: point,
            width: 14,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        );
      }
    }

    // Pending first tap marker (pulsing effect via larger size)
    if (_pendingPoint != null) {
      markers.add(
        Marker(
          point: _pendingPoint!,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildVehicleDropdown() {
    return Consumer<VehicleProvider>(
      builder: (context, provider, child) {
        if (provider.vehicles.isEmpty) {
          return Text(AppLocalizations.of(context)!.noVehicle);
        }

        if (_selectedVehicleId != null &&
            !provider.vehicles.any((v) => v.id == _selectedVehicleId)) {
          _selectedVehicleId = provider.vehicles.first.id;
        }

        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          value: _selectedVehicleId,
          items: provider.vehicles.map((v) {
            return DropdownMenuItem<int>(
              value: v.id,
              child: Text(
                '${v.year} ${v.brand} ${v.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedVehicleId = val;
            });
          },
        );
      },
    );
  }

  Widget _buildDateTimePicker() {
    final dateStr = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : '';
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          if (!mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: _selectedTime ?? TimeOfDay.now(),
          );
          if (time != null) {
            setState(() {
              _selectedDate = date;
              _selectedTime = time;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$dateStr $timeStr',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.parsedSession.routePoints;

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

    final l10n = AppLocalizations.of(context)!;

    final String statusText;
    if (_gates.isEmpty && _pendingPoint == null) {
      statusText = l10n.tapToDrawSF;
    } else if (_pendingPoint != null) {
      statusText = l10n.tapToCompleteGate;
    } else {
      statusText = l10n.gatesCount(_gates.length);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newRace),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _gates.isEmpty
                ? null
                : () async {
                    final customName = _nameController.text.trim();

                    final finalDate = DateTime(
                      _selectedDate?.year ?? widget.parsedSession.date.year,
                      _selectedDate?.month ?? widget.parsedSession.date.month,
                      _selectedDate?.day ?? widget.parsedSession.date.day,
                      _selectedTime?.hour ?? widget.parsedSession.date.hour,
                      _selectedTime?.minute ?? widget.parsedSession.date.minute,
                    );

                    final calculatedLaps = LapCalculatorService.calculateLaps(
                      routePoints: widget.parsedSession.routePoints,
                      routeSpeeds: widget.parsedSession.routeSpeeds,
                      sectorGates: _gates,
                      routeTimestamps: widget.parsedSession.routeTimestamps,
                    );

                    final sessionToSave = Session(
                      vehicleId:
                          _selectedVehicleId ?? widget.parsedSession.vehicleId,
                      date: finalDate,
                      importDate: DateTime.now(),
                      locationName: customName.isNotEmpty
                          ? customName
                          : widget.parsedSession.locationName,
                      durationMillis: widget.parsedSession.durationMillis,
                      totalDistanceMeters:
                          widget.parsedSession.totalDistanceMeters,
                      routePoints: widget.parsedSession.routePoints,
                      routeSpeeds: widget.parsedSession.routeSpeeds,
                      routeTimestamps: widget.parsedSession.routeTimestamps,
                      laps: calculatedLaps,
                      sectorGates: _gates,
                    );

                    await context.read<SessionProvider>().addSession(
                      sessionToSave,
                    );
                    await context.read<UserProvider>().refreshGlobalStats();
                    if (mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.nameYourRace,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildVehicleDropdown()),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildDateTimePicker()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: _pendingPoint != null
                              ? Colors.blue
                              : Colors.black54,
                          fontWeight: _pendingPoint != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_gates.isNotEmpty || _pendingPoint != null)
                      TextButton.icon(
                        onPressed: _undoLast,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(l10n.undo),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCameraFit: bounds != null
                        ? CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(32),
                          )
                        : null,
                    initialCenter: bounds == null
                        ? const LatLng(0, 0)
                        : bounds.center,
                    initialZoom: bounds == null ? 2 : 15,
                    cameraConstraint: const CameraConstraint.unconstrained(),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    minZoom: 1,
                    maxZoom: 30,
                    onTap: (tapPosition, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.moto_lap_timer',
                    ),
                    PolylineLayer(
                      polylines: [
                        ..._buildHeatmapPolylines(),
                        ..._buildGatePolylines(),
                      ],
                    ),
                    MarkerLayer(markers: _buildGateMarkers()),
                  ],
                ),
                // Clear all button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'clearGates',
                    onPressed: _clearAll,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.red,
                    child: const Icon(Icons.clear),
                  ),
                ),
                // Zoom buttons
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoomInCreate',
                        onPressed: _zoomIn,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: const Icon(Icons.add, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoomOutCreate',
                        onPressed: _zoomOut,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: const Icon(Icons.remove, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
