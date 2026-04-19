import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../utils/time_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SessionProvider>().loadSessions();
      await context.read<UserProvider>().refreshGlobalStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    final l10n = AppLocalizations.of(context)!;

    final user = userProvider.currentUser;
    final vehicle = vehicleProvider.currentVehicle;
    final sessions = sessionProvider.sessions;

    final double totalDistanceMeters = user?.totalDistanceMeters ?? 0;
    final int totalTimeMillis = user?.totalTimeMillis ?? 0;
    final int sessionsCount = user?.sessionsCount ?? 0;

    final double avgSpeedKmh = totalTimeMillis > 0
        ? (totalDistanceMeters / 1000.0) / (totalTimeMillis / 3600000.0)
        : 0;

    final int avgTimeMillis = sessionsCount > 0 ? totalTimeMillis ~/ sessionsCount : 0;

    int daysInApp = user != null
        ? DateTime.now().difference(user.joinDate).inDays
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),

          // Combined User & Vehicle Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.8),
                  Colors.deepOrange.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickname ?? l10n.rider,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            vehicle?.displayName ?? l10n.noVehicle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.lastRide}: ${_getLastRideDate(sessions)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Dashboards
          Text(
            l10n.yourStats,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),

          // Block 1 (2 tiles)
          Row(
            children: [
              Expanded(
                child: _buildDashboardTile(
                  icon: Icons.straighten,
                  title: l10n.distance,
                  value: '${(totalDistanceMeters / 1000).toStringAsFixed(1)}',
                  unit: 'km',
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDashboardTile(
                  icon: Icons.timer,
                  title: l10n.time,
                  value: TimeUtils.formatDurationConcise(totalTimeMillis),
                  unit: '',
                  color: Colors.deepOrangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Block 2 (2 tiles)
          Row(
            children: [
              Expanded(
                child: _buildDashboardTile(
                  icon: Icons.speed,
                  title: l10n.avgSpeed,
                  value: avgSpeedKmh.toStringAsFixed(1),
                  unit: 'km/h',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDashboardTile(
                  icon: Icons.balance,
                  title: l10n.avgTime,
                  value: TimeUtils.formatDurationConcise(avgTimeMillis),
                  unit: '',
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          //
          const SizedBox(height: 160), // padding for bottom nav
        ],
      ),
    );
  }

  String _getLastRideDate(List<dynamic> sessions) {
    if (sessions.isEmpty) return 'N/A';
    // Sessions are usually ordered by date DESC in database_helper
    final lastSession = sessions.first;
    final date = lastSession.date;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
