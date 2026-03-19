import 'package:flutter/material.dart';
import 'consultation.dart';

class Reply {
  final int replyId;
  final Consultation consultation;
  final String farmerName;
  final String senderName;
  final String replyMessage;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isVet;

  Reply({
    required this.replyId,
    required this.consultation,
    required this.farmerName,
    required this.senderName,
    required this.replyMessage,
    required this.createdAt,
    this.imageUrl,
    required this.isVet,
  });

  factory Reply.fromJson(Map<String, dynamic> json, Consultation consultation) {
    return Reply(
      replyId: json['reply_id'] ?? 0,
      consultation: consultation,
      farmerName: json['farmer_name'] ?? '',
      senderName: json['sender_name'] ?? 'Veterinarian',
      replyMessage: json['reply_message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'],
      isVet: json['is_vet'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply_id': replyId,
      'consultation_id': consultation.consultationId,
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