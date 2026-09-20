import 'package:flutter/material.dart';

/// ระบบสีสำหรับแอป Food Social สไตล์ Warm Gourmet Modern
/// คุมโทนให้อบอุ่น สดใส น่ารับประทาน ไม่แสบตา และมีคอนทราสต์ที่อ่านง่าย
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFFF9F6F0); // Warm cream / off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white card
  static const Color surfaceContainer = Color(0xFFF2ECE4); // Warm container
  static const Color surfaceVariant = Color(0xFFEFE8DE);

  // Brand / Primary
  static const Color primary = Color(0xFFFF5B22); // Warm appetizing orange
  static const Color primaryLight = Color(0xFFFFF2EC); // Soft orange tint
  static const Color primaryDark = Color(0xFFD94410);

  // Accents
  static const Color accentAmber = Color(0xFFF59E0B); // Star, highlights, tips
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentGreen = Color(0xFF10B981); // Fresh, healthy
  static const Color accentGreenLight = Color(0xFFD1FAE5);

  // Typography & Charcoal
  static const Color textPrimary = Color(0xFF1E2024); // Dark charcoal
  static const Color textSecondary = Color(0xFF5C616C); // Medium gray
  static const Color textMuted = Color(0xFF9EA3AE); // Light gray / caption
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE8E2D9); // Soft subtle border
  static const Color borderLight = Color(0xFFF0EBE3);

  // Social / Interactive
  static const Color likeActive = Color(0xFFFF3B30); // Vibrant heart red
  static const Color likeActiveBg = Color(0xFFFFECEB);
  static const Color saveActive = Color(0xFFFF9500); // Bookmark warm gold
  static const Color saveActiveBg = Color(0xFFFFF5E5);

  // Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 14,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];
}
