import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand color (vibrant active orange, reminiscent of premium sports brands)
  // Primary brand color (blue, representing trust & premium feel)
  static const Color primary = Color(0xFF0A84FF); // #0A84FF
  static const Color primaryDark = Color(0xFF0066CC); // darker shade for shadows
  static const Color primaryLight = Color(0xFFE0F0FF); // light tint for backgrounds

  // Secondary brand color (deep cool slate)
  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryLight = Color(0xFF1E293B);

  // Light Mode Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textLightPrimary = Color(0xFF0F172A);
  static const Color textLightSecondary = Color(0xFF64748B);
  static const Color textLightMuted = Color(0xFF94A3B8);

  // Dark Mode Colors (Sleek dark mode)
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF151C2C);
  static const Color borderDark = Color(0xFF242F48);
  static const Color textDarkPrimary = Color(0xFFF8FAFC);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textDarkMuted = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Accent Overlay & Glassmorphism
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassBg = Color(0x0DFFFFFF);
  static const Color shadowColor = Color(0x0F000000);
}
