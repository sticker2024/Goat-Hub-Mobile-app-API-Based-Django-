import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../models/consultation.dart';
import '../../models/user.dart';
import '../../models/cooperative.dart';
import '../../models/special_case.dart';
import '../../models/statistics_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../storage/secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<Map<String, String>> _getHeaders({bool multipart = false}) async {
    final token = await SecureStorage.read(AppConstants.tokenKey);
    return {
      if (!multipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  String _getFullUrl(String endpoint) {
    return '${AppConstants.baseUrl}$endpoint';
  }

  // ============= AUTH APIs =============

  Future<Map<String, dynamic>> login(String role, String userId, String password) async {
    try {
      print('🔵 ApiService: Login attempt - role: $role, userId: $userId');
      
      final response = await http.post(
        Uri.parse(_getFullUrl(ApiEndpoints.login)),
        headers: await _getHeaders(),
        body: json.encode({
          'role': role,
          'user_id': userId,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🔵 ApiService: Login response status: ${response.statusCode}');
      print('🔵 ApiService: Login response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data.containsKey('token')) {
          await SecureStorage.write(AppConstants.tokenKey, data['token']);
          _token = data['token'];
        }
        
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Login failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('🔴 ApiService: Login error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('🔵 ApiService: Register attempt');
      
      final response = await http.post(
        Uri.parse(_getFullUrl(ApiEndpoints.register)),
        headers: await _getHeaders(),
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 15));

      print('🔵 ApiService: Register response status: ${response.statusCode}');
      print('🔵 ApiService: Register response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('🔴 ApiService: Register error: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ============= FARMER APIs =============

  Future<List<Farmer>> getFarmers() async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.farmers)),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Farmer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching farmers: $e');
      return [];
    }
  }

  Future<Farmer?> getFarmerDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.farmerDetail(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Farmer.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching farmer detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getFarmerStats(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.farmerStats(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching farmer stats: $e');
      return {};
    }
  }

  // ============= CONSULTATION APIs =============

  Future<List<Consultation>> getConsultations() async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.consultations)),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching consultations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createConsultation(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(_getFullUrl(ApiEndpoints.createConsultation)),
        );
        
        final headers = await _getHeaders(multipart: true);
        request.headers.addAll(headers);
        
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);
        
        if (response.statusCode == 201) {
          return {'success': true, 'data': responseData};
        } else {
          return {'success': false, 'error': responseData['error'] ?? 'Failed to create consultation'};
        }
      } else {
        final response = await http.post(
          Uri.parse(_getFullUrl(ApiEndpoints.createConsultation)),
          headers: await _getHeaders(),
          body: json.encode(data),
        ).timeout(const Duration(seconds: 15));

        final responseData = json.decode(response.body);

        if (response.statusCode == 201) {
          return {'success': true, 'data': responseData};
        } else {
          return {'success': false, 'error': responseData['error'] ?? 'Failed to create consultation'};
        }
      }
    } catch (e) {
      print('Error creating consultation: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Reply>> getConsultationReplies(int consultationId) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.consultationReplies(consultationId))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
return data.map((json) => Reply.fromJson(json, consultationId: consultationId)).toList();      }
      return [];
    } catch (e) {
      print('Error fetching replies: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getConsultationConversation(int consultationId) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.consultationConversation(consultationId))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching conversation: $e');
      return {};
    }
  }

  Future<List<Consultation>> getFarmerConsultations(String farmerName) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.farmerConsultations(farmerName))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching farmer consultations: $e');
      return [];
    }
  }

  // ============= VETERINARIAN APIs =============

  Future<List<Veterinarian>> getVets() async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.vets)),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Veterinarian.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vets: $e');
      return [];
    }
  }

  Future<Veterinarian?> getVetDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.vetDetail(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Veterinarian.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching vet detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createReply(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(_getFullUrl(ApiEndpoints.createReply)),
        );
        
        final headers = await _getHeaders(multipart: true);
        request.headers.addAll(headers);
        
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'reply_image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);
        
        if (response.statusCode == 201) {
          return {'success': true, 'data': responseData};
        } else {
          return {'success': false, 'error': responseData['error'] ?? 'Failed to send reply'};
        }
      } else {
        final response = await http.post(
          Uri.parse(_getFullUrl(ApiEndpoints.createReply)),
          headers: await _getHeaders(),
          body: json.encode(data),
        ).timeout(const Duration(seconds: 15));

        final responseData = json.decode(response.body);

        if (response.statusCode == 201) {
          return {'success': true, 'data': responseData};
        } else {
          return {'success': false, 'error': responseData['error'] ?? 'Failed to send reply'};
        }
      }
    } catch (e) {
      print('Error creating reply: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendReplyEmail(int replyId) async {
    try {
      final response = await http.post(
        Uri.parse(_getFullUrl(ApiEndpoints.sendReplyEmail(replyId))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false};
    } catch (e) {
      print('Error sending email: $e');
      return {'success': false};
    }
  }

  // ============= COOPERATIVE APIs =============

  Future<List<Cooperative>> getCooperatives() async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.cooperatives)),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Cooperative.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching cooperatives: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getCooperativeDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.cooperativeDetail(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching cooperative detail: $e');
      return {};
    }
  }

  Future<List<CooperativeMember>> getCooperativeMembers(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.cooperativeMembers(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['members'] != null) {
          return (data['members'] as List)
              .map((json) => CooperativeMember.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cooperative members: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getCooperativeStats(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.cooperativeStats(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching cooperative stats: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> addCooperativeMember(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(_getFullUrl(ApiEndpoints.addCooperativeMember)),
        headers: await _getHeaders(),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('Error adding cooperative member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeCooperativeMember(int memberId) async {
    try {
      final response = await http.post(
        Uri.parse(_getFullUrl(ApiEndpoints.removeCooperativeMember(memberId))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return json.decode(response.body);
    } catch (e) {
      print('Error removing cooperative member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============= SPECIAL CASES APIs =============

  Future<List<SpecialCase>> getSpecialCases() async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.specialCases)),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SpecialCase.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching special cases: $e');
      return [];
    }
  }

  Future<SpecialCase?> getSpecialCaseDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.specialCaseDetail(id))),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SpecialCase.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching special case detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createSpecialCase(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(_getFullUrl(ApiEndpoints.specialCases)),
        );
        
        final headers = await _getHeaders(multipart: true);
        request.headers.addAll(headers);
        
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      } else {
        final response = await http.post(
          Uri.parse(_getFullUrl(ApiEndpoints.specialCases)),
          headers: await _getHeaders(),
          body: json.encode(data),
        ).timeout(const Duration(seconds: 15));

        return json.decode(response.body);
      }
    } catch (e) {
      print('Error creating special case: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============= STATISTICS APIs =============

  Future<Statistics?> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse(_getFullUrl(ApiEndpoints.statistics)),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Statistics.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching statistics: $e');
      return null;
    }
  }

  // ============= LOGOUT =============

  Future<void> logout() async {
    await SecureStorage.delete(AppConstants.tokenKey);
    _token = null;
  }
}