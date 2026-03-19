import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outlined ? color : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: outlined ? color : color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}