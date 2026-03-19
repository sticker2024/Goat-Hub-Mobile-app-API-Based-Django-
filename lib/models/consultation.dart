import 'package:flutter/material.dart';

class Consultation {
  final int consultationId;
  final String fullName;
  final String phoneNumber;
  final String location;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final int? assignedVetId;
  final List<Reply> replies;

  Consultation({
    required this.consultationId,
    required this.fullName,
    required this.phoneNumber,
    required this.location,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.assignedVetId,
    this.replies = const [],
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      consultationId: json['consultation_id'] ?? json['id'] ?? 0,
      fullName: json['full_name'] ?? json['farmer_name'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
      location: json['location'] ?? '',
      message: json['message'] ?? json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'] ?? json['image'],
      assignedVetId: json['assigned_vet'] ?? json['vet_id'],
      replies: json['replies'] != null
          ? (json['replies'] as List).map((r) => Reply.fromJson(r, consultationId: json['consultation_id'] ?? 0)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_id': consultationId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'location': location,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'image_url': imageUrl,
      'assigned_vet': assignedVetId,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'replied':
        return 'Replied';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'replied':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'in_progress':
        return Icons.autorenew;
      case 'replied':
        return Icons.check_circle;
      case 'closed':
        return Icons.lock;
      default:
        return Icons.help;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class Reply {
  final int replyId;
  final int consultationId;
  final String farmerName;
  final String senderName;
  final String replyMessage;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isVet;
  final Consultation? consultation; // Added this field

  Reply({
    required this.replyId,
    required this.consultationId,
    required this.farmerName,
    required this.senderName,
    required this.replyMessage,
    required this.createdAt,
    this.imageUrl,
    required this.isVet,
    this.consultation, // Added this parameter
  });

  factory Reply.fromJson(Map<String, dynamic> json, {required int consultationId, Consultation? consultation}) {
    return Reply(
      replyId: json['reply_id'] ?? json['id'] ?? 0,
      consultationId: consultationId,
      farmerName: json['farmer_name'] ?? json['farmer'] ?? '',
      senderName: json['sender_name'] ?? json['sender'] ?? 'Veterinarian',
      replyMessage: json['reply_message'] ?? json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'] ?? json['image'],
      isVet: json['is_vet'] ?? true,
      consultation: consultation, // Added this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply_id': replyId,
      'consultation_id': consultationId,
      'farmer_name': farmerName,
      'sender_name': senderName,
      'reply_message': replyMessage,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'is_vet': isVet,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color get senderColor {
    return isVet ? Colors.green : Colors.blue;
  }

  IconData get senderIcon {
    return isVet ? Icons.medical_services : Icons.admin_panel_settings;
  }
}