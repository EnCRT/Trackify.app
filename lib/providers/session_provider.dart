import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/database_helper.dart';

class SessionProvider with ChangeNotifier {
  List<Session> _sessions = [];
  bool _isLoading = false;

  List<Session> get sessions => _sessions;
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    _sessions = await DatabaseHelper().getSessions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSessionsForVehicle(int vehicleId) async {
    _isLoading = true;
    notifyListeners();

    _sessions = await DatabaseHelper().getSessionsForVehicle(vehicleId);

    _isLoading = false;
    notifyListeners();
  }

  Future<int> addSession(Session session) async {
    final insertedId = await DatabaseHelper().insertSession(session);
    final savedSession = Session(
      id: insertedId,
      vehicleId: session.vehicleId,
      date: session.date,
      importDate: session.importDate,
      locationName: session.locationName,
      durationMillis: session.durationMillis,
      totalDistanceMeters: session.totalDistanceMeters,
      routePoints: session.routePoints,
      routeSpeeds: session.routeSpeeds,
      routeTimestamps: session.routeTimestamps,
      laps: session.laps,
      sectorGates: session.sectorGates,
    );

    // Keep UI responsive: insert immediately, keep order newest-first.
    _sessions = [savedSession, ..._sessions.where((s) => s.id != insertedId)];
    notifyListeners();
    return insertedId;
  }

  Future<void> deleteSession(int sessionId) async {
    await DatabaseHelper().deleteSession(sessionId);
    await loadSessions();
  }

  Future<void> updateSession(Session session) async {
    await DatabaseHelper().updateSession(session);
    await loadSessions();
  }
}
