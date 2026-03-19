import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum SnackBarType { success, error, info, warning }

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color getColor() {
      switch (type) {
        case SnackBarType.success:
          return Colors.green;
        case SnackBarType.error:
          return Colors.red;
        case SnackBarType.warning:
          return Colors.orange;
        case SnackBarType.info:
          return Colors.blue;
      }
    }

    IconData getIcon() {
      switch (type) {
        case SnackBarType.success:
          return Icons.check_circle;
        case SnackBarType.error:
          return Icons.error;
        case SnackBarType.warning:
          return Icons.warning;
        case SnackBarType.info:
          return Icons.info;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(getIcon(), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: getColor(),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
      ),
    );
  }

  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatTime(DateTime date, {String format = 'HH:mm'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime date, {String format = 'MMM dd, yyyy HH:mm'}) {
    return DateFormat(format).format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static String formatPhoneNumber(String phone) {
    // Format Rwanda phone numbers: +250 788 123 456
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('+250') && cleaned.length == 13) {
      return '+${cleaned.substring(1, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
    } else if (cleaned.startsWith('07') && cleaned.length == 10) {
      return '+250 ${cleaned.substring(1, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    return phone;
  }

  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'replied':
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'in_progress':
        return Icons.autorenew;
      case 'replied':
        return Icons.check_circle;
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'closed':
        return Icons.lock;
      default:
        return Icons.help;
    }
  }
}