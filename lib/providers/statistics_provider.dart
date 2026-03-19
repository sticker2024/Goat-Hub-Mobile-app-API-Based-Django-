import 'package:flutter/material.dart';
import '../services/api/api_service.dart';
import '../models/statistics_model.dart';

class StatisticsProvider extends ChangeNotifier {
  Statistics? _statistics;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  Statistics? get statistics => _statistics;
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

  Future<void> loadStatistics() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _statistics = await ApiService().getStatistics();
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

  void clearError() {
    _error = null;
    _notifySafely();
  }
}