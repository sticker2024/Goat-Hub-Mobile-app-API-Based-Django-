import 'package:goathub/core/constants/app_constants.dart';

class ApiEndpoints {
  static const String baseUrl = AppConstants.baseUrl;
  // Auth endpoints
  static const String login = '/api/login/';
  static const String register = '/api/register/';
  static const String logout = '/api/logout/';
  static const String refreshToken = '/api/token/refresh/';
  
  // Farmer endpoints
  static const String farmers = '/api/farmers/';
  static String farmerDetail(int id) => '/api/farmers/$id/';
  static String farmerStats(int id) => '/api/farmers/$id/stats/';
  static String farmerConsultations(String name) => '/api/farmers/$name/consultations/';
  
  // Consultation endpoints
  static const String consultations = '/api/consultations/';
  static const String createConsultation = '/api/consultations/create/';
  static String consultationReplies(int id) => '/api/consultations/$id/replies/';
  static String consultationConversation(int id) => '/api/consultations/$id/conversation/';
  
  // Veterinarian endpoints
  static const String vets = '/api/vets/';
  static const String createReply = '/api/replies/create/';
  static String vetDetail(int id) => '/api/veterinarians/$id/';
  static String sendReplyEmail(int id) => '/api/replies/$id/send-email/';
  
  // Cooperative endpoints
  static const String cooperatives = '/api/cooperatives/';
  static String cooperativeDetail(int id) => '/api/cooperatives/$id/';
  static String cooperativeMembers(int id) => '/api/cooperatives/$id/members/';
  static String cooperativeStats(int id) => '/api/cooperatives/$id/stats/';
  static const String addCooperativeMember = '/api/cooperatives/add-member/';
  static String removeCooperativeMember(int id) => '/api/cooperatives/remove-member/$id/';
  
  // Special Cases endpoints
  static const String specialCases = '/api/special-cases/';
  static String specialCaseDetail(int id) => '/api/special-cases/$id/';
  
  // Statistics endpoints
  static const String statistics = '/api/statistics/';
  
  // Admin endpoints
  static const String adminFarmers = '/api/admin/farmers/';
  static const String adminVets = '/api/admin/veterinarians/';
  static const String adminCooperatives = '/api/admin/cooperatives/';
  static const String adminSpecialCases = '/api/admin/special-cases/';
  static const String adminStatistics = '/api/admin/statistics/';
}