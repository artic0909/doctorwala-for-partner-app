import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00796B); // Deep Teal
  static const Color primaryDark = Color(0xFF004D40);
  static const Color secondary = Color(0xFF00ACC1); // Light Blue/Cyan
  static const Color accent = Color(0xFFFFAB40); // Orange Accent
  
  static const Color background = Color(0xFFF5F7FA);
  static const Color white = Colors.white;
  static const Color black = Colors.black87;
  static const Color grey = Colors.grey;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF00796B), Color(0xFF004D40)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
