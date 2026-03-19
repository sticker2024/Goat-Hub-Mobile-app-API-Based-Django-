import 'package:flutter/material.dart';
import '../models/user.dart';  // This imports BaseUser, Farmer, Veterinarian, Administrator
import '../services/api/auth_api.dart';
import '../services/storage/local_storage.dart';
import '../core/constants/app_constants.dart';
import '../services/api/api_service.dart';
import '../services/storage/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  BaseUser? _currentUser;  // Changed from User? to BaseUser?
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  // Getters
  BaseUser? get currentUser => _currentUser;  // Changed to BaseUser?
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isFarmer => _currentUser?.userType == 'farmer';
  bool get isVet => _currentUser?.userType == 'vet';
  bool get isAdmin => _currentUser?.userType == 'admin';

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

  // Login method
  Future<bool> login(String role, String userId, String password) async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      print('🔵 AuthProvider: Starting login for role=$role, userId=$userId');
      
      final response = await AuthApi.login(role, userId, password);
      
      print('🔵 AuthProvider: Login response = $response');
      
      if (response['success'] == true) {
        // Extract user data from response
        String userType = response['role'] ?? role;
        String extractedUserId = response['user_id']?.toString() ?? 
                        response['id']?.toString() ?? 
                        response['id_number']?.toString() ?? 
                        '';
        String userName = response['user_name'] ?? 
                          response['username'] ?? 
                          response['full_name'] ?? 
                          'User';
        String email = response['email'] ?? '';
        String phone = response['phone'] ?? response['phone_number'] ?? '';
        String district = response['district'] ?? '';
        String sector = response['sector'] ?? '';
        String? profilePicture = response['profile_picture'];
        
        print('🔵 AuthProvider: Creating user with type=$userType, id=$extractedUserId, name=$userName');
        
        // Create user based on role
        if (userType == 'farmer') {
          _currentUser = Farmer(
            id: extractedUserId,
            userType: userType,
            username: userName,
            email: email,
            firstName: response['first_name'] ?? (userName.split(' ').isNotEmpty ? userName.split(' ')[0] : ''),
            lastName: response['last_name'] ?? (userName.split(' ').length > 1 ? userName.split(' ')[1] : ''),
            phone: phone,
            district: district,
            sector: sector,
            profilePicture: profilePicture,
            isActive: true,
            createdAt: DateTime.now(),
            farmerId: extractedUserId,
            idNumber: response['id_number'] ?? '',
            farmType: response['farm_type'] ?? 'individual',
            cooperativeName: response['cooperative_name'],
            farmSize: response['farm_size'] ?? 0,
            farmingExperience: response['farming_experience'] ?? 0,
            isVerified: response['is_verified'] ?? false,
          );
        } else if (userType == 'vet') {
          _currentUser = Veterinarian(
            id: extractedUserId,
            userType: userType,
            username: userName,
            email: email,
            firstName: response['first_name'] ?? (userName.split(' ').isNotEmpty ? userName.split(' ')[0] : ''),
            lastName: response['last_name'] ?? (userName.split(' ').length > 1 ? userName.split(' ')[1] : ''),
            phone: phone,
            district: district,
            sector: sector,
            profilePicture: profilePicture,
            isActive: true,
            createdAt: DateTime.now(),
            vetId: extractedUserId,
            licenseNumber: response['license_number'] ?? '',
            yearsExperience: response['years_experience'] ?? 0,
            specialization: response['specialization'] ?? 'general',
            clinicName: response['clinic_name'] ?? '',
            clinicAddress: response['clinic_address'] ?? '',
            isApproved: response['is_approved'] ?? false,
            approvedAt: response['approved_at'] != null ? DateTime.tryParse(response['approved_at'].toString()) : null,
          );
        } else if (userType == 'admin') {
          _currentUser = Administrator(
            id: extractedUserId,
            userType: userType,
            username: userName,
            email: email,
            firstName: response['first_name'] ?? (userName.split(' ').isNotEmpty ? userName.split(' ')[0] : ''),
            lastName: response['last_name'] ?? (userName.split(' ').length > 1 ? userName.split(' ')[1] : ''),
            phone: phone,
            district: district,
            sector: sector,
            profilePicture: profilePicture,
            isActive: true,
            createdAt: DateTime.now(),
            adminId: extractedUserId,
            employeeId: response['employee_id'] ?? '',
            department: response['department'] ?? '',
          );
        }
        
        // Save to local storage
        await LocalStorage.setString(AppConstants.userTypeKey, userType);
        await LocalStorage.setString(AppConstants.userIdKey, extractedUserId);
        await LocalStorage.setString(AppConstants.userNameKey, userName);
        await LocalStorage.setString(AppConstants.userEmailKey, email);
        await LocalStorage.setString(AppConstants.userPhoneKey, phone);
        if (district.isNotEmpty) {
          await LocalStorage.setString(AppConstants.userDistrictKey, district);
        }
        
        _isLoading = false;
        _notifySafely();
        print('🔵 AuthProvider: Login successful for user $userName');
        return true;
      } else {
        _error = response['error'] ?? 'Login failed';
        _isLoading = false;
        _notifySafely();
        print('🔴 AuthProvider: Login failed with error: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      _notifySafely();
      print('🔴 AuthProvider: Login exception: $e');
      return false;
    }
  }

  // Register method
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      print('🔵 AuthProvider: Starting registration');
      print('   Data: $userData');
      
      final response = await AuthApi.register(userData);
      
      print('🔵 AuthProvider: Register response = $response');
      
      if (response['success'] == true) {
        String userId = response['extracted_id'] ?? '';
        String userName = response['user_name'] ?? 
                          response['username'] ?? 
                          'User';
        String email = response['email'] ?? userData['email'] ?? '';
        String phone = response['phone'] ?? userData['phone'] ?? '';
        String district = response['district'] ?? userData['district'] ?? '';
        String sector = response['sector'] ?? userData['sector'] ?? '';
        String? profilePicture = response['profile_picture'];
        
        // Auto-login after registration based on role
        String role = userData['role'] ?? '';
        
        if (role == 'farmer') {
          _currentUser = Farmer(
            id: userId,
            userType: role,
            username: userName,
            email: email,
            firstName: response['first_name'] ?? userData['first_name'] ?? (userName.split(' ').isNotEmpty ? userName.split(' ')[0] : ''),
            lastName: response['last_name'] ?? userData['last_name'] ?? (userName.split(' ').length > 1 ? userName.split(' ')[1] : ''),
            phone: phone,
            district: district,
            sector: sector,
            profilePicture: profilePicture,
            isActive: true,
            createdAt: DateTime.now(),
            farmerId: userId,
            idNumber: response['id_number'] ?? userData['id_number'] ?? '',
            farmType: response['farm_type'] ?? userData['farm_type'] ?? 'individual',
            cooperativeName: response['cooperative_name'] ?? userData['cooperative_name'],
            farmSize: response['farm_size'] ?? userData['farm_size'] ?? 0,
            farmingExperience: response['farming_experience'] ?? userData['farming_experience'] ?? 0,
            isVerified: response['is_verified'] ?? false,
          );
        } else if (role == 'vet') {
          _currentUser = Veterinarian(
            id: userId,
            userType: role,
            username: userName,
            email: email,
            firstName: response['first_name'] ?? userData['first_name'] ?? (userName.split(' ').isNotEmpty ? userName.split(' ')[0] : ''),
            lastName: response['last_name'] ?? userData['last_name'] ?? (userName.split(' ').length > 1 ? userName.split(' ')[1] : ''),
            phone: phone,
            district: district,
            sector: sector,
            profilePicture: profilePicture,
            isActive: true,
            createdAt: DateTime.now(),
            vetId: userId,
            licenseNumber: response['license_number'] ?? userData['license_number'] ?? '',
            yearsExperience: response['years_experience'] ?? userData['years_experience'] ?? 0,
            specialization: response['specialization'] ?? userData['specialization'] ?? 'general',
            clinicName: response['clinic_name'] ?? userData['clinic_name'] ?? '',
            clinicAddress: response['clinic_address'] ?? userData['clinic_address'] ?? '',
            isApproved: response['is_approved'] ?? false,
            approvedAt: response['approved_at'] != null ? DateTime.tryParse(response['approved_at'].toString()) : null,
          );
        } else if (role == 'admin') {
          _currentUser = Administrator(
            id: userId,
            userType: role,
            username: userName,
            email: email,
            firstName: response['first_name'] ?? userData['first_name'] ?? (userName.split(' ').isNotEmpty ? userName.split(' ')[0] : ''),
            lastName: response['last_name'] ?? userData['last_name'] ?? (userName.split(' ').length > 1 ? userName.split(' ')[1] : ''),
            phone: phone,
            district: district,
            sector: sector,
            profilePicture: profilePicture,
            isActive: true,
            createdAt: DateTime.now(),
            adminId: userId,
            employeeId: response['employee_id'] ?? userData['employee_id'] ?? '',
            department: response['department'] ?? userData['department'] ?? '',
          );
        }
        
        // Save to local storage
        await LocalStorage.setString(AppConstants.userTypeKey, role);
        await LocalStorage.setString(AppConstants.userIdKey, userId);
        await LocalStorage.setString(AppConstants.userNameKey, userName);
        await LocalStorage.setString(AppConstants.userEmailKey, email);
        await LocalStorage.setString(AppConstants.userPhoneKey, phone);
        if (district.isNotEmpty) {
          await LocalStorage.setString(AppConstants.userDistrictKey, district);
        }
        
        _isLoading = false;
        _notifySafely();
        print('🔵 AuthProvider: Registration successful for user $userName');
        return true;
      } else {
        _error = response['error'] ?? 'Registration failed';
        _isLoading = false;
        _notifySafely();
        print('🔴 AuthProvider: Registration failed with error: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      _notifySafely();
      print('🔴 AuthProvider: Registration exception: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      await ApiService().logout();
    } catch (e) {
      print('🔴 AuthProvider: Logout API error: $e');
    } finally {
      await LocalStorage.clear();
      await SecureStorage.clear();
      _currentUser = null;
      _notifySafely();
      print('🔵 AuthProvider: User logged out');
    }
  }

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    final userType = await LocalStorage.getString(AppConstants.userTypeKey);
    final userId = await LocalStorage.getString(AppConstants.userIdKey);
    final userName = await LocalStorage.getString(AppConstants.userNameKey);
    final userEmail = await LocalStorage.getString(AppConstants.userEmailKey);
    final userPhone = await LocalStorage.getString(AppConstants.userPhoneKey);
    final userDistrict = await LocalStorage.getString(AppConstants.userDistrictKey);
    
    if (userType != null && userId != null && userName != null) {
      // Create appropriate user type based on stored role
      if (userType == 'farmer') {
        _currentUser = Farmer(
          id: userId,
          userType: userType,
          username: userName,
          email: userEmail ?? '',
          firstName: userName.split(' ').isNotEmpty ? userName.split(' ')[0] : '',
          lastName: userName.split(' ').length > 1 ? userName.split(' ')[1] : '',
          phone: userPhone ?? '',
          district: userDistrict ?? '',
          sector: '',
          profilePicture: null,
          isActive: true,
          createdAt: DateTime.now(),
          farmerId: userId,
          idNumber: '',
          farmType: 'individual',
          cooperativeName: null,
          farmSize: 0,
          farmingExperience: 0,
          isVerified: false,
        );
      } else if (userType == 'vet') {
        _currentUser = Veterinarian(
          id: userId,
          userType: userType,
          username: userName,
          email: userEmail ?? '',
          firstName: userName.split(' ').isNotEmpty ? userName.split(' ')[0] : '',
          lastName: userName.split(' ').length > 1 ? userName.split(' ')[1] : '',
          phone: userPhone ?? '',
          district: userDistrict ?? '',
          sector: '',
          profilePicture: null,
          isActive: true,
          createdAt: DateTime.now(),
          vetId: userId,
          licenseNumber: '',
          yearsExperience: 0,
          specialization: 'general',
          clinicName: '',
          clinicAddress: '',
          isApproved: true,
          approvedAt: null,
        );
      } else if (userType == 'admin') {
        _currentUser = Administrator(
          id: userId,
          userType: userType,
          username: userName,
          email: userEmail ?? '',
          firstName: userName.split(' ').isNotEmpty ? userName.split(' ')[0] : '',
          lastName: userName.split(' ').length > 1 ? userName.split(' ')[1] : '',
          phone: userPhone ?? '',
          district: userDistrict ?? '',
          sector: '',
          profilePicture: null,
          isActive: true,
          createdAt: DateTime.now(),
          adminId: userId,
          employeeId: '',
          department: '',
        );
      }
      
      print('🔵 AuthProvider: Restored user session for $userName');
      _notifySafely();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    _notifySafely();
  }
}