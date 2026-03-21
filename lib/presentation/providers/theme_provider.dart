import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';

// 🌍 Global Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  // Shuru mein 'premiumTeal' (Default) set karega
  ThemeNotifier() : super(AppThemeMode.premiumTeal) {
    _loadTheme(); // App khulte hi purani theme load karega
  }

  // 📥 Memory se purani theme nikalna
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Agar koi theme save nahi hai, toh 0 (premiumTeal) uthayega
    final themeIndex = prefs.getInt('app_theme') ?? 0;

    // Index ko wapis Enum (AppThemeMode) mein badalna
    final mode = AppThemeMode.values[themeIndex];

    AppColors.applyTheme(mode); // Colors change karega
    state = mode; // UI ko update karega
  }

  // 💾 Nayi theme save karna (Jab user Profile se color change kare)
  Future<void> changeTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    // Theme ka number memory mein save kar lo
    await prefs.setInt('app_theme', mode.index);

    AppColors.applyTheme(mode); // Background mein colors change karega
    state = mode; // Pori app ko foran naye colors par repaint (refresh) karega
  }
}