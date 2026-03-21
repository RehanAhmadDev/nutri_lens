import 'package:flutter/material.dart';

// 🎨 6 Premium Themes define ki hain
enum AppThemeMode {
  premiumTeal,
  sunsetOrange,
  royalPurple,
  roseRed,
  midnightBlue,
  emeraldForest
}

class AppColors {
  // 🚀 `const` hata diya taake colors live tabdeel ho sakein
  static Color primary = const Color(0xFF0D9488);     // Default: Deep Teal
  static Color secondary = const Color(0xFF0284C7);   // Default: Ocean Blue

  // 📝 Text & Background colors (Yeh wahi premium slate tones hain)
  static Color textDark = const Color(0xFF0F172A);
  static Color textLight = const Color(0xFF64748B);
  static Color background = const Color(0xFFF8FAFC);
  static Color cardColor = Colors.white;
  static Color error = const Color(0xFFE11D48);
  static Color success = const Color(0xFF10B981);

  // ⚙️ Jadoo wala function jo theme change karega
  static void applyTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.sunsetOrange:
        primary = const Color(0xFFEA580C);   // Warm energetic orange
        secondary = const Color(0xFFF59E0B); // Amber
        break;
      case AppThemeMode.royalPurple:
        primary = const Color(0xFF7C3AED);   // Premium Purple
        secondary = const Color(0xFFA78BFA); // Soft Violet
        break;
      case AppThemeMode.roseRed:
        primary = const Color(0xFFE11D48);   // Elegant Rose
        secondary = const Color(0xFFFB7185); // Soft Pink
        break;
      case AppThemeMode.midnightBlue:
        primary = const Color(0xFF1E3A8A);   // Deep Professional Blue
        secondary = const Color(0xFF3B82F6); // Bright Blue
        break;
      case AppThemeMode.emeraldForest:
        primary = const Color(0xFF047857);   // Rich Forest Green
        secondary = const Color(0xFF34D399); // Light Mint
        break;
      case AppThemeMode.premiumTeal:
      default:
      // 🌟 Aapki Original Theme Wapis!
        primary = const Color(0xFF0D9488);
        secondary = const Color(0xFF0284C7);
        break;
    }
  }
}