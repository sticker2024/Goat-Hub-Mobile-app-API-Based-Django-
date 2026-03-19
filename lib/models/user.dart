
abstract class BaseUser {
  final String id;
  final String userType;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String district;
  final String sector;
  final String? profilePicture;
  final bool isActive;
  final DateTime createdAt;

  BaseUser({
    required this.id,
    required this.userType,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.district,
    required this.sector,
    this.profilePicture,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  
  Map<String, dynamic> toJson();
}

class Farmer extends BaseUser {
  final String farmerId;
  final String idNumber;
  final String farmType;
  final String? cooperativeName;
  final int farmSize;
  final int farmingExperience;
  final bool isVerified;

  Farmer({
    required super.id,
    required super.userType,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.phone,
    required super.district,
    required super.sector,
    super.profilePicture,
    required super.isActive,
    required super.createdAt,
    required this.farmerId,
    required this.idNumber,
    required this.farmType,
    this.cooperativeName,
    required this.farmSize,
    required this.farmingExperience,
    required this.isVerified,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      userType: json['user_type'] ?? json['role'] ?? 'farmer',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? json['phone_number'] ?? '',
      district: json['district'] ?? '',
      sector: json['sector'] ?? '',
      profilePicture: json['profile_picture'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      farmerId: json['farmer_id'] ?? '',
      idNumber: json['id_number'] ?? '',
      farmType: json['farm_type'] ?? 'individual',
      cooperativeName: json['cooperative_name'],
      farmSize: json['farm_size'] ?? 0,
      farmingExperience: json['farming_experience'] ?? 0,
      isVerified: json['is_verified'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_type': userType,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'district': district,
      'sector': sector,
      'profile_picture': profilePicture,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'farmer_id': farmerId,
      'id_number': idNumber,
      'farm_type': farmType,
      'cooperative_name': cooperativeName,
      'farm_size': farmSize,
      'farming_experience': farmingExperience,
      'is_verified': isVerified,
    };
  }
}

class Veterinarian extends BaseUser {
  final String vetId;
  final String licenseNumber;
  final int yearsExperience;
  final String specialization;
  final String clinicName;
  final String clinicAddress;
  final bool isApproved;
  final DateTime? approvedAt;

  Veterinarian({
    required super.id,
    required super.userType,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.phone,
    required super.district,
    required super.sector,
    super.profilePicture,
    required super.isActive,
    required super.createdAt,
    required this.vetId,
    required this.licenseNumber,
    required this.yearsExperience,
    required this.specialization,
    required this.clinicName,
    required this.clinicAddress,
    required this.isApproved,
    this.approvedAt,
  });

  factory Veterinarian.fromJson(Map<String, dynamic> json) {
    return Veterinarian(
      id: json['id']?.toString() ?? json['vet_id']?.toString() ?? '',
      userType: json['user_type'] ?? json['role'] ?? 'vet',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      district: json['district'] ?? '',
      sector: json['sector'] ?? '',
      profilePicture: json['profile_picture'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      vetId: json['vet_id'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      yearsExperience: json['years_experience'] ?? 0,
      specialization: json['specialization'] ?? 'general',
      clinicName: json['clinic_name'] ?? '',
      clinicAddress: json['clinic_address'] ?? '',
      isApproved: json['is_approved'] ?? false,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
    );
  }

  String get specializationDisplay {
    switch (specialization) {
      case 'general':
        return 'General Veterinary';
      case 'surgery':
        return 'Surgery';
      case 'reproduction':
        return 'Reproduction';
      case 'nutrition':
        return 'Nutrition';
      case 'preventive':
        return 'Preventive Care';
      default:
        return specialization;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_type': userType,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'district': district,
      'sector': sector,
      'profile_picture': profilePicture,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'vet_id': vetId,
      'license_number': licenseNumber,
      'years_experience': yearsExperience,
      'specialization': specialization,
      'clinic_name': clinicName,
      'clinic_address': clinicAddress,
      'is_approved': isApproved,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}

class Administrator extends BaseUser {
  final String adminId;
  final String employeeId;
  final String department;

  Administrator({
    required super.id,
    required super.userType,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.phone,
    required super.district,
    required super.sector,
    super.profilePicture,
    required super.isActive,
    required super.createdAt,
    required this.adminId,
    required this.employeeId,
    required this.department,
  });

  factory Administrator.fromJson(Map<String, dynamic> json) {
    return Administrator(
      id: json['id']?.toString() ?? json['admin_id']?.toString() ?? '',
      userType: json['user_type'] ?? json['role'] ?? 'admin',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      district: json['district'] ?? '',
      sector: json['sector'] ?? '',
      profilePicture: json['profile_picture'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      adminId: json['admin_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      department: json['department'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_type': userType,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'district': district,
      'sector': sector,
      'profile_picture': profilePicture,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'admin_id': adminId,
      'employee_id': employeeId,
      'department': department,
    };
  }
}