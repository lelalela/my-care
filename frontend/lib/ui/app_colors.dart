import 'package:flutter/material.dart';

/// My-Care 디자인 시스템 컬러 토큰
/// 의료적 신뢰감(Clinical Vitality)을 상징하는 Deep Teal을 메인으로 사용합니다.
abstract final class AppColors {
  // Brand Primary (Vital Teal)
  static const Color primary = Color(0xFF007A87);
  static const Color primaryContainer = Color(0xFFC7E7EC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF002024);

  // Secondary (Calm Sage / Soft Green)
  static const Color secondary = Color(0xFF386A63);
  static const Color secondaryContainer = Color(0xFFBCECE3);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00201C);

  // Accent / Clinical Warning & Highlights
  static const Color amberHighlight = Color(0xFFD97706);
  static const Color amberContainer = Color(0xFFFEF3C7);
  static const Color redAlert = Color(0xFFDC2626);
  static const Color redContainer = Color(0xFFFEE2E2);

  // Neutral & Surfaces (Clean Medical Paper)
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
}
