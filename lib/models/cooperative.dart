class Cooperative {
  final int cooperativeId;
  final String name;
  final String? registrationNumber;
  final String district;
  final String sector;
  final String? cell;
  final String? village;
  final String leaderName;
  final String leaderPhone;
  final String? leaderEmail;
  final String? leaderIdNumber;
  final String? description;
  final DateTime registrationDate;
  final int totalMembers;
  final int totalGoats;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cooperative({
    required this.cooperativeId,
    required this.name,
    this.registrationNumber,
    required this.district,
    required this.sector,
    this.cell,
    this.village,
    required this.leaderName,
    required this.leaderPhone,
    this.leaderEmail,
    this.leaderIdNumber,
    this.description,
    required this.registrationDate,
    required this.totalMembers,
    required this.totalGoats,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cooperative.fromJson(Map<String, dynamic> json) {
    return Cooperative(
      cooperativeId: json['cooperative_id'] ?? 0,
      name: json['name'] ?? '',
      registrationNumber: json['registration_number'],
      district: json['district'] ?? '',
      sector: json['sector'] ?? '',
      cell: json['cell'],
      village: json['village'],
      leaderName: json['leader_name'] ?? '',
      leaderPhone: json['leader_phone'] ?? '',
      leaderEmail: json['leader_email'],
      leaderIdNumber: json['leader_id_number'],
      description: json['description'],
      registrationDate: DateTime.parse(json['registration_date'] ?? DateTime.now().toIso8601String()),
      totalMembers: json['total_members'] ?? 0,
      totalGoats: json['total_goats'] ?? 0,
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get fullAddress {
    final parts = [district, sector];
    if (cell != null) parts.add(cell!);
    if (village != null) parts.add(village!);
    return parts.join(', ');
  }
}

class CooperativeMember {
  final int memberId;
  final int cooperativeId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String? idNumber;
  final int farmSize;
  final String? farmLocation;
  final String role;
  final DateTime joinedDate;
  final bool isActive;
  final DateTime createdAt;

  CooperativeMember({
    required this.memberId,
    required this.cooperativeId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.idNumber,
    required this.farmSize,
    this.farmLocation,
    required this.role,
    required this.joinedDate,
    required this.isActive,
    required this.createdAt,
  });

  factory CooperativeMember.fromJson(Map<String, dynamic> json) {
    return CooperativeMember(
      memberId: json['member_id'] ?? 0,
      cooperativeId: json['cooperative'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      idNumber: json['id_number'],
      farmSize: json['farm_size'] ?? 0,
      farmLocation: json['farm_location'],
      role: json['role'] ?? 'member',
      joinedDate: DateTime.parse(json['joined_date'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get fullName => '$firstName $lastName';
  
  String get roleDisplay {
    switch (role) {
      case 'leader':
        return 'Leader';
      case 'secretary':
        return 'Secretary';
      case 'treasurer':
        return 'Treasurer';
      case 'vice_leader':
        return 'Vice Leader';
      default:
        return 'Member';
    }
  }
}