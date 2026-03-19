import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFFD700);
  static const Color secondaryDark = Color(0xFFFFA000);
  
  // Accent Colors
  static const Color vet = Color(0xFF00695C);
  static const Color vetDark = Color(0xFF004D40);
  static const Color admin = Color(0xFF283593);
  static const Color adminDark = Color(0xFF1A237E);
  
  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);
  static const Color border = Color(0xFFE0E0E0);
  
  // Gradient combinations
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient vetGradient = LinearGradient(
    colors: [vet, vetDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient adminGradient = LinearGradient(
    colors: [admin, adminDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}