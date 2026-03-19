import 'package:flutter/material.dart';

class SpecialCase {
  final int caseId;
  final String district;
  final String sector;
  final String description;
  final String status;
  final bool reportedToRab;
  final DateTime reportedAt;
  final String? imageUrl;

  SpecialCase({
    required this.caseId,
    required this.district,
    required this.sector,
    required this.description,
    required this.status,
    required this.reportedToRab,
    required this.reportedAt,
    this.imageUrl,
  });

  factory SpecialCase.fromJson(Map<String, dynamic> json) {
    return SpecialCase(
      caseId: json['case_id'] ?? 0,
      district: json['district'] ?? '',
      sector: json['sector'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'reported',
      reportedToRab: json['reported_to_rab'] ?? false,
      reportedAt: DateTime.parse(json['reported_at'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'reported':
        return 'Reported';
      case 'in_review':
        return 'In Review';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'reported':
        return Colors.red;
      case 'in_review':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'reported':
        return Icons.warning;
      case 'in_review':
        return Icons.search;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}