import 'package:flutter/material.dart';
import '../services/api/api_service.dart';
import '../models/user.dart';
class FarmerProvider extends ChangeNotifier {
  List<Farmer> _farmers = [];
  Farmer? _selectedFarmer;
  final Map<int, Map<String, dynamic>> _farmerStats = {};
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  List<Farmer> get farmers => _farmers;
  Farmer? get selectedFarmer => _selectedFarmer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  Future<void> loadFarmers() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _farmers = await ApiService().getFarmers();
      _isLoading = false;
      _notifySafely();
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _isLoading = false;
        _notifySafely();
      }
    }
  }

  Future<void> loadFarmerDetail(int id) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final farmer = await ApiService().getFarmerDetail(id);
      if (farmer != null) {
        _selectedFarmer = farmer;
      }
      _isLoading = false;
      _notifySafely();
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _isLoading = false;
        _notifySafely();
      }
    }
  }

  Future<Map<String, dynamic>> loadFarmerStats(int id) async {
    if (_isDisposed) return {};

    try {
      final stats = await ApiService().getFarmerStats(id);
      _farmerStats[id] = stats;
      return stats;
    } catch (e) {
      print('Error loading farmer stats: $e');
      return {};
    }
  }

  Map<String, dynamic>? getFarmerStats(int id) {
    return _farmerStats[id];
  }

  List<String> getDistricts() {
    return _farmers
        .map((f) => f.district)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
  }

  int getTotalFarmers() {
    return _farmers.length;
  }

  Map<String, int> getFarmersByDistrict() {
    final Map<String, int> result = {};
    for (var farmer in _farmers) {
      result[farmer.district] = (result[farmer.district] ?? 0) + 1;
    }
    return result;
  }

  void selectFarmer(Farmer farmer) {
    _selectedFarmer = farmer;
    _notifySafely();
  }

  void clearSelected() {
    _selectedFarmer = null;
    _notifySafely();
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }
}