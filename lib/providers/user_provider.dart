import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get needsProfileOnboarding => _currentUser == null && !_isLoading;

  UserProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await DatabaseHelper().getUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUser(User user) async {
    await DatabaseHelper().insertUser(user);
    await loadUser();
  }
}
