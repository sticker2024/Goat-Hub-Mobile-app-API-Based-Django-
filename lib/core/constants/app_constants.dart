class AppConstants {
  static const String appName = 'Goat Health Hub';
  static const String appVersion = '1.0.0';
  
  // API Base URL - IMPORTANT: Use your computer's IP address
  // For physical device: Use your computer's local IP (e.g., http://192.168.1.100:8000)
  // For emulator: Use 10.0.2.2 for Android emulator, or localhost for iOS simulator
  //static const String baseUrl = 'http://172.16.18.218:8000'; // Update this to match your Django server IP
  //static const String baseUrl = 'http://172.31.172.207:8080';
  static const String baseUrl = 'http://localhost:8000';  // For web development


  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userPhoneKey = 'user_phone';
  static const String userDistrictKey = 'user_district';
  
  // Pagination
  static const int pageSize = 20;
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  
  // Image Upload Limits
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png'];
}