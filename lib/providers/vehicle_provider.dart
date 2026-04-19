import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _currentVehicle;
  bool _isLoading = true;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get currentVehicle => _currentVehicle;
  bool get isLoading => _isLoading;
  bool get needsOnboarding => _vehicles.isEmpty && !_isLoading;

  VehicleProvider() {
    loadVehicles();
  }

  Future<void> loadVehicles({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    _vehicles = await DatabaseHelper().getVehicles();

    // Find favorite or use first
    final favorite = _vehicles.where((v) => v.isFavorite == true).firstOrNull;
    if (favorite != null) {
      _currentVehicle = favorite;
    } else if (_vehicles.isNotEmpty) {
      _currentVehicle = _vehicles.first;
    } else {
      _currentVehicle = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await DatabaseHelper().insertVehicle(vehicle);
    await loadVehicles(silent: true);
  }

  Future<void> setFavorite(Vehicle vehicle) async {
    if (vehicle.id == null) return;
    await DatabaseHelper().setVehicleFavorite(vehicle.id!);
    await loadVehicles(silent: true);
  }

  void setCurrentVehicle(Vehicle vehicle) {
    _currentVehicle = vehicle;
    notifyListeners();
  }
}
