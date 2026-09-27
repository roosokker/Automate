import 'package:flutter/material.dart';

/// Nocturne design tokens — dark blue-grey ground, blurple accent used as
/// line + glow. Every color in the app comes from here.
class AppColors {
  AppColors._();

  // Ground & surfaces
  static const Color bg = Color(0xFF161826);
  static const Color surfaceLow = Color(0xFF1C1E2C);
  static const Color surface = Color(0xFF232532);
  static const Color surfaceHigh = Color(0xFF2C2E3D);
  static const Color section = Color(0xFF262A60);
  static const Color sectionGlow = Color(0xFF353B80);

  // Text
  static const Color text = Color(0xFFE9E9ED);
  static const Color textSecondary = Color(0xFFCFD3E5); // neutral-300
  static const Color textMuted = Color(0xFFB2B6CA); // neutral-400
  static const Color textFaint = Color(0xFF9397AB); // neutral-500

  // Lines
  static const Color line = Color(0x29E9E9ED); // text @ 16%
  static const Color lineStrong = Color(0xFF595D6C); // neutral-700

  // Accent ramp
  static const Color accent = Color(0xFF9184D9);
  static const Color accent100 = Color(0xFFF5F4FF);
  static const Color accent200 = Color(0xFFE7E5FE);
  static const Color accent300 = Color(0xFFD2CEFD);
  static const Color accent400 = Color(0xFFB5ABFC);
  static const Color accent600 = Color(0xFF796CBF);
  static const Color accent700 = Color(0xFF5D5294);
  static const Color accentDeep = Color(0xFF423A6A); // accent-800
  static const Color accentTint = Color(0xFF2B2741); // accent-900

  static const Color accent500 = Color(0xFF968AE0);
  static const Color sectionGhost = Color(0xFF4C5397);

  // Neutral ramp (extra steps)
  static const Color neutral100 = Color(0xFFF3F5FE);
  static const Color neutral200 = Color(0xFFE4E7F5);
  static const Color neutral700 = Color(0xFF595D6C);
  static const Color neutral600 = Color(0xFF75798C);
  static const Color neutral800 = Color(0xFF3F424D);
  static const Color neutral900 = Color(0xFF292B31);

  // Status
  static const Color ok = Color(0xFF7FD1AE);
  static const Color okTint = Color(0xFF1F3330);
  static const Color warn = Color(0xFFE8B04B);
  static const Color warnTint = Color(0xFF3A3122);
  static const Color danger = Color(0xFFE0736A);
  static const Color dangerTint = Color(0xFF3A2328);
  static const Color dangerLine = Color(0xFF6B3A3C);

  /// Soft accent glow used under primary actions and active marks.
  static List<BoxShadow> glow([double opacity = 0.35, double blur = 24]) => [
        BoxShadow(color: accent.withValues(alpha: opacity), blurRadius: blur),
      ];

  /// Nocturne rules fade to transparent at both ends.
  static const LinearGradient fadingRule = LinearGradient(
    colors: [Color(0x00E9E9ED), line, line, Color(0x00E9E9ED)],
    stops: [0.0, 0.12, 0.88, 1.0],
  );
}
