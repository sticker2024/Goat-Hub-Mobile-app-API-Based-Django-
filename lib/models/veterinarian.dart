class Veterinarian {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String specialization;
  final String district;
  final bool isApproved;
  final int yearsExperience;
  final String? licenseNumber;

  Veterinarian({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.district,
    required this.isApproved,
    required this.yearsExperience,
    this.licenseNumber,
  });

  factory Veterinarian.fromJson(Map<String, dynamic> json) {
    return Veterinarian(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      specialization: json['specialization'] ?? 'General',
      district: json['district'] ?? '',
      isApproved: json['is_approved'] ?? false,
      yearsExperience: json['years_experience'] ?? 0,
      licenseNumber: json['license_number'],
    );
  }

  String get fullName => 'Dr.  \';$firstName $lastName';
}
