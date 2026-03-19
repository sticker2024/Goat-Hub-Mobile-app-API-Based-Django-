import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class ApiClient {
  static const String baseUrl = AppConstants.baseUrl;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Network error: $e', 'success': false};
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Network error: $e', 'success': false};
    }
  }

  static Future<Map<String, dynamic>> postWithAuth(
    String endpoint, 
    Map<String, dynamic> data, 
    String token
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: getAuthHeaders(token),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Network error: $e', 'success': false};
    }
  }

  static Future<Map<String, dynamic>> putWithAuth(
    String endpoint, 
    Map<String, dynamic> data, 
    String token
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: getAuthHeaders(token),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Network error: $e', 'success': false};
    }
  }

  static Future<Map<String, dynamic>> deleteWithAuth(
    String endpoint, 
    String token
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: getAuthHeaders(token),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Network error: $e', 'success': false};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': _parseError(data),
          'statusCode': response.statusCode,
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse response: $e',
        'statusCode': response.statusCode,
      };
    }
  }

  static String _parseError(dynamic data) {
    if (data is Map) {
      if (data.containsKey('error')) return data['error'];
      if (data.containsKey('message')) return data['message'];
      if (data.containsKey('detail')) return data['detail'];
      
      if (data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'] as List;
        return errors.join(', ');
      }
      
      List<String> fieldErrors = [];
      data.forEach((key, value) {
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
  }
}