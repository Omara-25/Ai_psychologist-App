import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define theme colors for different themes
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
  });
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _colorTheme = 'purple'; // Default theme

  // Available color themes
  final Map<String, ThemeColors> themeColors = {
    'purple': const ThemeColors(
      primary: Color(0xFF6A11CB),
      secondary: Color(0xFF2575FC),
      background: Color(0xFFF5F5F5),
      surface: Color(0xFFFFFFFF),
    ),
    'blue': const ThemeColors(
      primary: Color(0xFF1A73E8),
      secondary: Color(0xFF66B2FF),
      background: Color(0xFFF8F9FA),
      surface: Color(0xFFFFFFFF),
    ),
    'green': const ThemeColors(
      primary: Color(0xFF0F9D58),
      secondary: Color(0xFF66BB6A),
      background: Color(0xFFF1F8E9),
      surface: Color(0xFFFFFFFF),
    ),
    'orange': const ThemeColors(
      primary: Color(0xFFFF5722),
      secondary: Color(0xFFFF8A65),
      background: Color(0xFFFBE9E7),
      surface: Color(0xFFFFFFFF),
    ),
    'teal': const ThemeColors(
      primary: Color(0xFF00695C),
      secondary: Color(0xFF26A69A),
      background: Color(0xFFE0F2F1),
      surface: Color(0xFFFFFFFF),
    ),
    'pink': const ThemeColors(
      primary: Color(0xFFC2185B),
      secondary: Color(0xFFE91E63),
      background: Color(0xFFFCE4EC),
      surface: Color(0xFFFFFFFF),
    ),
    'indigo': const ThemeColors(
      primary: Color(0xFF283593),
      secondary: Color(0xFF3F51B5),
      background: Color(0xFFE8EAF6),
      surface: Color(0xFFFFFFFF),
    ),
    'amber': const ThemeColors(
      primary: Color(0xFFFF8F00),
      secondary: Color(0xFFFFC107),
      background: Color(0xFFFFF8E1),
      surface: Color(0xFFFFFFFF),
    ),
    'red': const ThemeColors(
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFFF44336),
      background: Color(0xFFFFEBEE),
      surface: Color(0xFFFFFFFF),
    ),
    'cyan': const ThemeColors(
      primary: Color(0xFF0097A7),
      secondary: Color(0xFF00BCD4),
      background: Color(0xFFE0F7FA),
      surface: Color(0xFFFFFFFF),
    ),
  };

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get colorTheme => _colorTheme;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Get current theme colors
  ThemeColors get currentThemeColors => themeColors[_colorTheme]!;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final savedColorTheme = prefs.getString('colorTheme') ?? 'purple';

    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _colorTheme = themeColors.containsKey(savedColorTheme) ? savedColorTheme : 'purple';

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setColorTheme(String themeName) async {
    if (!themeColors.containsKey(themeName)) return;

    _colorTheme = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colorTheme', themeName);
    notifyListeners();
  }

  // Get light theme based on current color theme
  ThemeData getLightTheme() {
    final colors = currentThemeColors;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        surfaceTint: colors.background,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  // Get dark theme based on current color theme
  ThemeData getDarkTheme() {
    final colors = currentThemeColors;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: colors.primary.withAlpha(230), // Slightly dimmed for dark mode
        secondary: colors.secondary.withAlpha(230),
        surface: const Color(0xFF1E1E1E),
        surfaceTint: const Color(0xFF121212),
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
