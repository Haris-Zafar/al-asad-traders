import 'package:flutter/material.dart';

/// Centralized color palette for Al Asad Traders ERP
abstract class AppColors {
  // Primary - Deep Slate Navy
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF334155);
  static const Color primaryContainer = Color(0xFFF1F5F9);

  // Accent / Success - Emerald Green
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);

  // Warning / Alert - Warm Amber
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Error - Red
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Surface & Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Neutral / Shimmer
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
