class Statistics {
  final int totalFarmers;
  final int totalVets;
  final int totalConsultations;
  final int totalReplies;
  final int pendingConsultations;
  final int pendingVets;
  final int repliedConsultations;
  final int inProgressConsultations;

  Statistics({
    required this.totalFarmers,
    required this.totalVets,
    required this.totalConsultations,
    required this.totalReplies,
    required this.pendingConsultations,
    required this.pendingVets,
    required this.repliedConsultations,
    required this.inProgressConsultations,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalFarmers: json['total_farmers'] ?? 0,
      totalVets: json['total_vets'] ?? 0,
      totalConsultations: json['total_consultations'] ?? 0,
      totalReplies: json['total_replies'] ?? 0,
      pendingConsultations: json['pending_consultations'] ?? 0,
      pendingVets: json['pending_vets'] ?? 0,
      repliedConsultations: json['replied_consultations'] ?? 0,
      inProgressConsultations: json['in_progress_consultations'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_farmers': totalFarmers,
      'total_vets': totalVets,
      'total_consultations': totalConsultations,
      'total_replies': totalReplies,
      'pending_consultations': pendingConsultations,
      'pending_vets': pendingVets,
      'replied_consultations': repliedConsultations,
      'in_progress_consultations': inProgressConsultations,
    };
  }
}