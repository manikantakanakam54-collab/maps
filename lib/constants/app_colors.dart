import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFFF58220); // LPU Brand Orange
  static const Color primaryDark = Color(0xFFD66A10);
  static const Color primaryLight = Color(0xFFFF9E47);
  static const Color primaryMuted = Color(0xFFFFF3E0);

  // Secondary & Accents
  static const Color secondary = Color(0xFF1E293B); // Deep Navy/Slate
  static const Color accent = Color(0xFF0284C7); // Sky Blue
  static const Color routeGreen = Color(0xFF10B981); // Emerald Green
  static const Color offRouteRed = Color(0xFFEF4444); // Bright Red
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Light surfaces
  static const Color surfaceLight = Colors.white;
  static const Color surfaceLightSecondary = Color(0xFFF8FAFC);
  static const Color textLightPrimary = Color(0xFF0F172A);
  static const Color textLightSecondary = Color(0xFF64748B);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceDarkCard = Color(0xFF1E293B);
  static const Color textDarkPrimary = Color(0xFFF8FAFC);
  static const Color textDarkSecondary = Color(0xFF94A3B8);

  // Category Icon Colors
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Academic Blocks':
        return const Color(0xFF3B82F6); // Blue
      case 'Library':
        return const Color(0xFF8B5CF6); // Purple
      case 'Hostels':
        return const Color(0xFFEC4899); // Pink
      case 'Administration':
        return const Color(0xFFF58220); // LPU Orange
      case 'Food Courts':
        return const Color(0xFF10B981); // Emerald Green
      case 'Sports':
        return const Color(0xFF06B6D4); // Cyan
      case 'Hospitals':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
