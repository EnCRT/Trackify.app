import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../services/gps_parser_service.dart';
import '../providers/session_provider.dart';
import '../providers/vehicle_provider.dart';

import 'main_feed_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'race_creation_screen.dart';
import 'session_detail_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  bool _isImportInProgress = false;
  int? _pendingAutoOpenSessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // Important for floating/translucent nav bars
      body: SafeArea(bottom: false, child: _buildCurrentScreen(l10n)),
      bottomNavigationBar: _buildBottomNavigationBar(l10n),
    );
  }

  Widget _buildCurrentScreen(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen(); // The new home screen
      case 1:
        return MainFeedScreen(
          autoOpenSessionId: _pendingAutoOpenSessionId,
          onAutoOpenConsumed: () {
            if (!mounted) return;
            setState(() {
              _pendingAutoOpenSessionId = null;
            });
          },
        ); // Will be updated to match the design
      case 2:
        return Center(
          child: Text(l10n.importing),
        ); // Shouldn't be reached ideally
      case 3:
        return const ProfileScreen(); // Profile Screen
      default:
        return const HomeScreen();
    }
  }

  void _onImportTapped() async {
    if (_isImportInProgress) return;
    setState(() {
      _isImportInProgress = true;
    });

    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.currentVehicle == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseAddVehicle),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isImportInProgress = false;
        });
      } else {
        _isImportInProgress = false;
      }
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String extension = result.files.single.extension ?? '';
        final parser = GpsParserService();
        int vehicleId = vehicleProvider.currentVehicle!.id!;

        // Show loading dialog? Maybe not needed for now.

        dynamic parsedSession;
        if (extension == 'gpx') {
          parsedSession = await parser.parseGpxFile(File(filePath), vehicleId);
        } else if (extension == 'txt') {
          parsedSession = await parser.parseTxtFile(File(filePath), vehicleId);
        } else {
          throw Exception('Unsupported file format');
        }

        if (mounted) {
          final result = await Navigator.of(context).push<int>(
            MaterialPageRoute(
              builder: (context) =>
                  RaceCreationScreen(parsedSession: parsedSession),
            ),
          );

          if (result != null && mounted) {
            setState(() {
              _currentIndex = 1; // Switch to Feed tab
              _pendingAutoOpenSessionId = result;
            });

            // After showing the feed (and allowing the new card animation),
            // automatically open session details.
            Future.delayed(const Duration(milliseconds: 2000), () async {
              if (!mounted) return;
              final targetId = _pendingAutoOpenSessionId;
              if (targetId == null) return;

              final provider = context.read<SessionProvider>();

              Session? session;
              for (final s in provider.sessions) {
                if (s.id == targetId) {
                  session = s;
                  break;
                }
              }

              session ??= await _loadAndFindSessionById(provider, targetId);
              if (!mounted || session == null) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionDetailScreen(session: session!),
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorParsingFile(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImportInProgress = false;
        });
      } else {
        _isImportInProgress = false;
      }
    }
  }

  Widget _buildBottomNavigationBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(43, 198, 174, 255),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _onImportTapped();
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.white,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 32),
              activeIcon: const Icon(Icons.home, size: 32),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_outlined, size: 32),
              activeIcon: const Icon(Icons.list_alt, size: 32),
              label: l10n.feed,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline, size: 32),
              activeIcon: const Icon(Icons.add_circle, size: 32),
              label: l10n.add,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline, size: 32),
              activeIcon: const Icon(Icons.person, size: 32),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }

  Future<Session?> _loadAndFindSessionById(
    SessionProvider provider,
    int sessionId,
  ) async {
    await provider.loadSessions();
    for (final s in provider.sessions) {
      if (s.id == sessionId) return s;
    }
    return null;
  }
}
