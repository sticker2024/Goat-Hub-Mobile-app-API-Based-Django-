import 'dart:io';
import '../models/consultation.dart';
import 'package:flutter/material.dart';
import '../services/api/api_service.dart';


class ConsultationProvider extends ChangeNotifier {
  List<Consultation> _consultations = [];
  List<Reply> _replies = [];
  Consultation? _selectedConsultation;
  final Map<int, List<Reply>> _repliesByConsultation = {};
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  List<Consultation> get consultations => _consultations;
  List<Reply> get replies => _replies;
  Consultation? get selectedConsultation => _selectedConsultation;
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

  Future<void> loadConsultations() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _consultations = await ApiService().getConsultations();
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

  Future<void> loadFarmerConsultations(String farmerName) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _consultations = await ApiService().getFarmerConsultations(farmerName);
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

  Future<void> loadConsultationReplies(int consultationId) async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _replies = await ApiService().getConsultationReplies(consultationId);
      _repliesByConsultation[consultationId] = _replies;
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

  Future<Map<String, dynamic>> loadConversation(int consultationId) async {
    if (_isDisposed) return {};

    try {
      return await ApiService().getConsultationConversation(consultationId);
    } catch (e) {
      print('Error loading conversation: $e');
      return {};
    }
  }

  Future<bool> createConsultation(Map<String, dynamic> data, {File? imageFile}) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final result = await ApiService().createConsultation(data, imageFile: imageFile);
      
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadConsultations();
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

  Future<bool> createReply(Map<String, dynamic> data, {File? imageFile}) async {
    if (_isDisposed) return false;
    
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final result = await ApiService().createReply(data, imageFile: imageFile);
      
      _isLoading = false;
      
      if (result['success'] == true) {
        final consultationId = data['consultation_id'] as int;
        await loadConsultationReplies(consultationId);
        await loadConsultations(); // Refresh consultations to update status
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

  Future<bool> sendReplyEmail(int replyId) async {
    try {
      final result = await ApiService().sendReplyEmail(replyId);
      return result['success'] == true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  void selectConsultation(Consultation consultation) {
    _selectedConsultation = consultation;
    _notifySafely();
  }

  void clearSelected() {
    _selectedConsultation = null;
    _notifySafely();
  }

  List<Consultation> getConsultationsByStatus(String status) {
    return _consultations.where((c) => c.status == status).toList();
  }

  int getPendingCount() {
    return _consultations.where((c) => c.status == 'pending').length;
  }

  int getInProgressCount() {
    return _consultations.where((c) => c.status == 'in_progress').length;
  }

  int getRepliedCount() {
    return _consultations.where((c) => c.status == 'replied').length;
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }
}