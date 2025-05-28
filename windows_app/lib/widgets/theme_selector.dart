import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_psychologist_windows/providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark mode toggle
          SwitchListTile(
            title: Row(
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
              ],
            ),
            value: isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
          // Color theme selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Color Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildThemeOption(context, 'purple', 'Purple'),
              _buildThemeOption(context, 'blue', 'Blue'),
              _buildThemeOption(context, 'green', 'Green'),
              _buildThemeOption(context, 'orange', 'Orange'),
              _buildThemeOption(context, 'teal', 'Teal'),
              _buildThemeOption(context, 'pink', 'Pink'),
              _buildThemeOption(context, 'indigo', 'Indigo'),
              _buildThemeOption(context, 'amber', 'Amber'),
              _buildThemeOption(context, 'red', 'Red'),
              _buildThemeOption(context, 'cyan', 'Cyan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String themeName, String displayName) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = themeProvider.colorTheme == themeName;
    final themeColors = themeProvider.themeColors[themeName]!;
    final primaryColor = themeColors.primary;
    final secondaryColor = themeColors.secondary;

    return InkWell(
      onTap: () => themeProvider.setColorTheme(themeName),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      )
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 30,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
