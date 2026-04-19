import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/session.dart';
import 'session_detail_screen.dart';

class MainFeedScreen extends StatefulWidget {
  final int? autoOpenSessionId;
  final VoidCallback? onAutoOpenConsumed;

  const MainFeedScreen({
    super.key,
    this.autoOpenSessionId,
    this.onAutoOpenConsumed,
  });

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  int? _vehicleFilterId; // null = all vehicles
  int? _pendingSessionId;
  bool _playNewSessionAnimation = false;

  @override
  void initState() {
    super.initState();
    _pendingSessionId = widget.autoOpenSessionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
      _maybeAnimateAndAutoOpen();
    });
  }

  @override
  void didUpdateWidget(covariant MainFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpenSessionId != oldWidget.autoOpenSessionId) {
      _pendingSessionId = widget.autoOpenSessionId;
      _playNewSessionAnimation = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAnimateAndAutoOpen();
      });
    }
  }

  void _maybeAnimateAndAutoOpen() {
    final targetId = _pendingSessionId;
    if (targetId == null || !mounted) return;

    // Consume immediately so switching tabs doesn't retrigger.
    widget.onAutoOpenConsumed?.call();

    // Kick animation on next build.
    setState(() {
      _playNewSessionAnimation = true;
    });
  }

  void _deleteSession(Session session) async {
    await context.read<SessionProvider>().deleteSession(session.id!);
    await context.read<UserProvider>().refreshGlobalStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.sessionDeleted)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SessionProvider, VehicleProvider>(
      builder: (context, provider, vehicleProvider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange),
          );
        }

        final sessions = _vehicleFilterId == null
            ? provider.sessions
            : provider.sessions
                .where((s) => s.vehicleId == _vehicleFilterId)
                .toList();

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_motorsports,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noSessionsYet,
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                ),
                Text(
                  AppLocalizations.of(context)!.addFirstSession,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
            //   child: Row(
            //     children: [
            //       const Spacer(),
            //       DropdownButton<int?>(
            //         value: _vehicleFilterId,
            //         underline: const SizedBox.shrink(),
            //         onChanged: (value) {
            //           setState(() => _vehicleFilterId = value);
            //         },
            //         items: [
            //           DropdownMenuItem<int?>(
            //             value: null,
            //             child: Text(AppLocalizations.of(context)!.allVehicles),
            //           ),
            //           ...vehicleProvider.vehicles
            //               .where((v) => v.id != null)
            //               .map(
            //                 (v) => DropdownMenuItem<int?>(
            //                   value: v.id!,
            //                   child: Text(v.displayName),
            //                 ),
            //               ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isNewlyAdded =
                      _pendingSessionId != null && session.id == _pendingSessionId;

                  final card = Dismissible(
                    key: Key('session_${session.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 30.0),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title:
                                Text(AppLocalizations.of(context)!.deleteSession),
                            content: Text(
                              AppLocalizations.of(context)!.deleteSessionConfirm,
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      _deleteSession(session);
                    },
                    child: _buildSessionCard(context, session, vehicleProvider),
                  );

                  if (!isNewlyAdded) return card;

                  return AnimatedSlide(
                    offset: _playNewSessionAnimation
                        ? Offset.zero
                        : const Offset(0, 0.08),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _playNewSessionAnimation ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: card,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    Session session,
    VehicleProvider vehicleProvider,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final dateObj = session.date;

    final String durationString = session.formattedDuration;
    final String distanceString =
        '${(session.totalDistanceMeters / 1000).toStringAsFixed(2)} km';

    final double durationHours = session.durationMillis / 3600000.0;
    final String avgSpeedString = durationHours > 0
        ? '${((session.totalDistanceMeters / 1000) / durationHours).toStringAsFixed(1)} km/h'
        : '0 km/h';

    final vehicleName =
        vehicleProvider.vehicles.any((v) => v.id == session.vehicleId)
        ? vehicleProvider.vehicles
              .firstWhere((v) => v.id == session.vehicleId)
              .displayName
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailScreen(session: session),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6), // Glass effect
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.locationName.isNotEmpty
                              ? session.locationName
                              : AppLocalizations.of(context)!.unknownTrack,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.trackedOn(dateFormat.format(dateObj)),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        if (vehicleName.isNotEmpty)
                          Text(
                            vehicleName,
                            style: TextStyle(
                              color: Colors.deepOrange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: _buildStatColumn(
                      AppLocalizations.of(context)!.distance,
                      distanceString,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  Flexible(
                    child: _buildStatColumn(
                      AppLocalizations.of(context)!.duration,
                      durationString,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  Flexible(
                    child: _buildStatColumn(
                      AppLocalizations.of(context)!.avgSpeed,
                      avgSpeedString,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
