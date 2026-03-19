import 'dart:io';
import '../models/special_case.dart';
import 'package:flutter/material.dart';
import '../services/api/api_service.dart';

class SpecialCaseProvider extends ChangeNotifier {
  List<SpecialCase> _specialCases = [];
  SpecialCase? _selectedCase;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  List<SpecialCase> get specialCases => _specialCases;
  SpecialCase? get selectedCase => _selectedCase;
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

  Future<void> loadSpecialCases() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _specialCases = await ApiService().getSpecialCases();
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

  Future<void> loadSpecialCaseDetail(int id) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final specialCase = await ApiService().getSpecialCaseDetail(id);
      if (specialCase != null) {
        _selectedCase = specialCase;
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

  Future<bool> createSpecialCase(Map<String, dynamic> data, {File? imageFile}) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final result = await ApiService().createSpecialCase(data, imageFile: imageFile);
      
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadSpecialCases();
        return true;
      } else {
        _error = result['error'];
        _notifySafely();
        return false;
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _isLoading = false;
        _notifySafely();
      }
      return false;
    }
  }

  int getUrgentCount() {
    return _specialCases
        .where((c) => c.status == 'reported' && !c.reportedToRab)
        .length;
  }

  int getReportedToRabCount() {
    return _specialCases.where((c) => c.reportedToRab).length;
  }

  void selectCase(SpecialCase specialCase) {
    _selectedCase = specialCase;
    _notifySafely();
  }

  void clearSelected() {
    _selectedCase = null;
    _notifySafely();
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }
}