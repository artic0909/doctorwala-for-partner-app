import 'package:flutter/material.dart';

class AppColors {
  // Precise palette from the splash image
  static const Color navy = Color(0xFF1A3B70); 
  static const Color teal = Color(0xFF34B091); 
  static const Color skyBlue = Color(0xFFE3F2FD);
  static const Color waveBlue = Color(0xFF90CAF9); // Color to match the bottom wavy asset
  
  static const Color primary = Color(0xFF34B091);
  static const Color secondary = Color(0xFF1A3B70);
  
  static const Color background = Color(0xFFF9FBFF);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF1A3B70);
  static const Color textSecondary = Color(0xFF6E7FA9);

  static const LinearGradient getStartedGradient = LinearGradient(
    colors: [Color(0xFF34B091), Color(0xFF1A3B70)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
