import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../../core/constants/api_endpoints.dart';

class AuthApi {
  // Login method
  static Future<Map<String, dynamic>> login(String role, String userId, String password) async {
    try {
      print('🔵 AuthApi: Sending login request');
      print('   URL: ${ApiClient.baseUrl}${ApiEndpoints.login}');
      print('   Body: {"role": "$role", "user_id": "$userId", "password": "***"}');
      
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiEndpoints.login}'),
        headers: ApiClient.headers,
        body: json.encode({
          'role': role,
          'user_id': userId,
          'password': password,
        }),
      );

      print('🔵 AuthApi: Response status: ${response.statusCode}');
      print('🔵 AuthApi: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          ...data,
        };
      } else {
        return {
          'success': false,
          'error': _parseError(response.body),
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('🔴 AuthApi: Network error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Register method
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('🔵 AuthApi: Sending registration request');
      print('   URL: ${ApiClient.baseUrl}${ApiEndpoints.register}');
      print('   Body: $userData');
      
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiEndpoints.register}'),
        headers: ApiClient.headers,
        body: json.encode(userData),
      );

      print('🔵 AuthApi: Register response status: ${response.statusCode}');
      print('🔵 AuthApi: Register response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract ID based on role and response format
        String userId = '';
        String userRole = userData['role'] ?? '';
        
        // Try different possible ID fields
        if (data.containsKey('id')) {
          userId = data['id'].toString();
        } else if (data.containsKey('user_id')) {
          userId = data['user_id'].toString();
        } else if (data.containsKey('employee_id')) {
          userId = data['employee_id'].toString();
        } else if (data.containsKey('farmer_id')) {
          userId = data['farmer_id'].toString();
        } else if (data.containsKey('vet_id')) {
          userId = data['vet_id'].toString();
        } else if (data.containsKey('admin_id')) {
          userId = data['admin_id'].toString();
        } else if (data.containsKey('id_number')) {
          userId = data['id_number'].toString();
        } else if (data.containsKey('data') && data['data'] is Map) {
          final nestedData = data['data'] as Map;
          if (nestedData.containsKey('id')) {
            userId = nestedData['id'].toString();
          } else if (nestedData.containsKey('user_id')) userId = nestedData['user_id'].toString();
          else if (nestedData.containsKey('employee_id')) userId = nestedData['employee_id'].toString();
        }
        
        // If still no ID, check for username or email as fallback
        if (userId.isEmpty && data.containsKey('username')) {
          userId = data['username'];
        }
        
        return {
          'success': true,
          ...data,
          'extracted_id': userId,
        };
      } else {
        return {
          'success': false,
          'error': _parseError(response.body),
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('🔴 AuthApi: Registration error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Logout method
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final headers = {
        ...ApiClient.headers,
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}${ApiEndpoints.logout}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': _parseError(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Forgot password method
  static Future<Map<String, dynamic>> forgotPassword(String email, String role) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/forgot-password/'),
        headers: ApiClient.headers,
        body: json.encode({
          'email': email,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset link sent to your email'};
      } else {
        return {
          'success': false,
          'error': _parseError(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Helper method to parse error responses
  static String _parseError(String responseBody) {
    try {
      final error = json.decode(responseBody);
      
      if (error is Map) {
        if (error.containsKey('error')) {
          return error['error'] as String;
        }
        if (error.containsKey('message')) {
          return error['message'] as String;
        }
        if (error.containsKey('detail')) {
          return error['detail'] as String;
        }
        
        if (error.containsKey('non_field_errors')) {
          final errors = error['non_field_errors'] as List;
          return errors.join(', ');
        }
        
        List<String> fieldErrors = [];
        error.forEach((key, value) {
          if (value is List) {
            fieldErrors.add('$key: ${value.join(', ')}');
          } else if (value is String) {
            fieldErrors.add('$key: $value');
          }
        });
        
        if (fieldErrors.isNotEmpty) {
          return fieldErrors.join('\n');
        }
      }
      
      return 'Request failed';
    } catch (e) {
      return 'Request failed';
    }
  }
}