import '../models/user.dart';
import 'package:flutter/material.dart';
import '../services/api/api_service.dart';

class VetProvider extends ChangeNotifier {
  List<Veterinarian> _vets = [];
  Veterinarian? _selectedVet;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  List<Veterinarian> get vets => _vets;
  Veterinarian? get selectedVet => _selectedVet;
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

  Future<void> loadVets() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _vets = await ApiService().getVets();
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

  Future<void> loadVetDetail(int id) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final vet = await ApiService().getVetDetail(id);
      if (vet != null) {
        _selectedVet = vet;
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

  int getPendingCount() {
    return _vets.where((v) => !v.isApproved).length;
  }

  int getApprovedCount() {
    return _vets.where((v) => v.isApproved).length;
  }

  List<String> getSpecializations() {
    return _vets
        .map((v) => v.specialization)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  void selectVet(Veterinarian vet) {
    _selectedVet = vet;
    _notifySafely();
  }

  void clearSelected() {
    _selectedVet = null;
    _notifySafely();
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }
}