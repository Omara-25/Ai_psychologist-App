import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_psychologist/providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7, // Limit height to 70% of screen
        maxWidth: screenWidth * 0.9,   // Limit width to 90% of screen
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Color theme selector
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              child: Text(
                'Color Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: screenWidth > 600 ? 5 : 3, // Responsive grid for more themes
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              mainAxisSpacing: screenWidth * 0.02,
              crossAxisSpacing: screenWidth * 0.02,
              childAspectRatio: screenWidth > 600 ? 0.8 : 0.9, // Responsive aspect ratio
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
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String themeName, String displayName) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = themeProvider.colorTheme == themeName;
    final themeColors = ThemeProvider.themeColors[themeName]!;
    final isDarkMode = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use the appropriate color based on the current theme mode
    final primaryColor = isDarkMode ? themeColors.darkPrimary : themeColors.lightPrimary;
    final secondaryColor = isDarkMode ? themeColors.darkSecondary : themeColors.lightSecondary;

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
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: screenWidth * 0.06, // Responsive icon size
                    )
                  : null,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Flexible(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                fontSize: screenWidth * 0.03, // Responsive font size
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
