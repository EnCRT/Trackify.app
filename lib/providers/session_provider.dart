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

  Future<void> addSession(Session session) async {
    await DatabaseHelper().insertSession(session);
    await loadSessions();
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
