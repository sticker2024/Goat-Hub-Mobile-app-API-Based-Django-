import '../models/cooperative.dart';
import 'package:flutter/material.dart';
import '../services/api/api_service.dart';

class CooperativeProvider extends ChangeNotifier {
  List<Cooperative> _cooperatives = [];
  List<CooperativeMember> _members = [];
  Cooperative? _selectedCooperative;
  final Map<int, Map<String, dynamic>> _cooperativeStats = {};
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  List<Cooperative> get cooperatives => _cooperatives;
  List<CooperativeMember> get members => _members;
  Cooperative? get selectedCooperative => _selectedCooperative;
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

  Future<void> loadCooperatives() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _cooperatives = await ApiService().getCooperatives();
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

  Future<void> loadCooperativeDetail(int id) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final data = await ApiService().getCooperativeDetail(id);
      if (data.isNotEmpty) {
        // You might want to create a detailed cooperative model
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

  Future<void> loadCooperativeMembers(int id) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _members = await ApiService().getCooperativeMembers(id);
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

  Future<Map<String, dynamic>> loadCooperativeStats(int id) async {
    if (_isDisposed) return {};

    try {
      final stats = await ApiService().getCooperativeStats(id);
      _cooperativeStats[id] = stats;
      return stats;
    } catch (e) {
      print('Error loading cooperative stats: $e');
      return {};
    }
  }

  Future<bool> addMember(Map<String, dynamic> data) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final result = await ApiService().addCooperativeMember(data);
      
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadCooperativeMembers(data['cooperative_id']);
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

  Future<bool> removeMember(int memberId, int cooperativeId) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final result = await ApiService().removeCooperativeMember(memberId);
      
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadCooperativeMembers(cooperativeId);
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

  void selectCooperative(Cooperative cooperative) {
    _selectedCooperative = cooperative;
    _notifySafely();
  }

  void clearSelected() {
    _selectedCooperative = null;
    _members = [];
    _notifySafely();
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }
}