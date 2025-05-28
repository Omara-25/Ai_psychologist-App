import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _colorTheme = 'purple'; // Default color theme

  // Theme color constants
  static const Map<String, ThemeColors> themeColors = {
    'purple': ThemeColors(
      lightPrimary: Color(0xFF6A11CB),
      lightSecondary: Color(0xFF2575FC),
      darkPrimary: Color(0xFF9D6FFF),
      darkSecondary: Color(0xFF5E9CFF),
    ),
    'green': ThemeColors(
      lightPrimary: Color(0xFF2E7D32),
      lightSecondary: Color(0xFF66BB6A),
      darkPrimary: Color(0xFF81C784),
      darkSecondary: Color(0xFFA5D6A7),
    ),
    'blue': ThemeColors(
      lightPrimary: Color(0xFF1565C0),
      lightSecondary: Color(0xFF42A5F5),
      darkPrimary: Color(0xFF64B5F6),
      darkSecondary: Color(0xFF90CAF9),
    ),
    'orange': ThemeColors(
      lightPrimary: Color(0xFFE65100),
      lightSecondary: Color(0xFFFF9800),
      darkPrimary: Color(0xFFFFB74D),
      darkSecondary: Color(0xFFFFCC80),
    ),
    'teal': ThemeColors(
      lightPrimary: Color(0xFF00695C),
      lightSecondary: Color(0xFF26A69A),
      darkPrimary: Color(0xFF4DB6AC),
      darkSecondary: Color(0xFF80CBC4),
    ),
    'pink': ThemeColors(
      lightPrimary: Color(0xFFC2185B),
      lightSecondary: Color(0xFFE91E63),
      darkPrimary: Color(0xFFF06292),
      darkSecondary: Color(0xFFF8BBD9),
    ),
    'indigo': ThemeColors(
      lightPrimary: Color(0xFF283593),
      lightSecondary: Color(0xFF3F51B5),
      darkPrimary: Color(0xFF7986CB),
      darkSecondary: Color(0xFF9FA8DA),
    ),
    'amber': ThemeColors(
      lightPrimary: Color(0xFFFF8F00),
      lightSecondary: Color(0xFFFFC107),
      darkPrimary: Color(0xFFFFCA28),
      darkSecondary: Color(0xFFFFE082),
    ),
    'red': ThemeColors(
      lightPrimary: Color(0xFFD32F2F),
      lightSecondary: Color(0xFFF44336),
      darkPrimary: Color(0xFFEF5350),
      darkSecondary: Color(0xFFFFCDD2),
    ),
    'cyan': ThemeColors(
      lightPrimary: Color(0xFF0097A7),
      lightSecondary: Color(0xFF00BCD4),
      darkPrimary: Color(0xFF26C6DA),
      darkSecondary: Color(0xFF80DEEA),
    ),
  };

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get colorTheme => _colorTheme;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Get current theme colors
  ThemeColors get currentThemeColors => themeColors[_colorTheme]!;

  // Constructor
  ThemeProvider() {
    _loadThemePreferences();
  }

  // Load saved preferences
  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final savedColorTheme = prefs.getString('colorTheme') ?? 'purple';

    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _colorTheme = themeColors.containsKey(savedColorTheme) ? savedColorTheme : 'purple';

    notifyListeners();
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  // Change color theme
  Future<void> setColorTheme(String themeName) async {
    if (!themeColors.containsKey(themeName)) return;

    _colorTheme = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colorTheme', themeName);
    notifyListeners();
  }

  // Get ThemeData for light mode
  ThemeData getLightTheme() {
    final colors = currentThemeColors;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: colors.lightPrimary,
        secondary: colors.lightSecondary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
    );
  }

  // Get ThemeData for dark mode
  ThemeData getDarkTheme() {
    final colors = currentThemeColors;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: colors.darkPrimary,
        secondary: colors.darkSecondary,
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[800],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
    );
  }
}

// Class to hold theme colors
class ThemeColors {
  final Color lightPrimary;
  final Color lightSecondary;
  final Color darkPrimary;
  final Color darkSecondary;

  const ThemeColors({
    required this.lightPrimary,
    required this.lightSecondary,
    required this.darkPrimary,
    required this.darkSecondary,
  });
}
