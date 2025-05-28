import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_psychologist/providers/theme_provider.dart';
import 'package:ai_psychologist/screens/app_details_screen.dart';
import 'package:ai_psychologist/screens/chat_screen.dart';
import 'package:ai_psychologist/screens/settings_screen.dart';
import 'package:ai_psychologist/screens/chat_history_screen.dart';
import 'package:ai_psychologist/screens/user_dashboard_screen.dart';
import 'package:ai_psychologist/utils/page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _drawerContentsOpacity;
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _drawerContentsOpacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userEmail = prefs.getString('userEmail') ?? '';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, Widget screen, String routeName) {
    if (widget.currentRoute == routeName) {
      Navigator.pop(context); // Close drawer if we're already on this screen
      return;
    }

    Navigator.pop(context); // Close drawer
    Navigator.pushReplacement(
      context,
      CustomPageTransition(
        child: screen,
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;

    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: FadeTransition(
        opacity: _drawerContentsOpacity,
        child: SafeArea(
          child: Column(
            children: [
              // User header
              Container(
                height: 140, // Fixed height instead of percentage
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  margin: const EdgeInsets.only(bottom: 8.0), // Add margin for better spacing
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24, // Reduced radius to prevent overflow
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 24, // Reduced icon size
                    ),
                  ),
                  accountName: Text(
                    _userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15, // Slightly smaller font size
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent text overflow
                  ),
                  accountEmail: Text(
                    _userEmail.isNotEmpty ? _userEmail : 'AI Psychologist User',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                      fontSize: 12, // Smaller font size
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent text overflow
                  ),
                ),
              ),

              // Navigation items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: widget.currentRoute == '/dashboard',
                      onTap: () => _navigateTo(context, const UserDashboardScreen(), '/dashboard'),
                    ),

                    _buildDrawerItem(
                      context: context,
                      icon: Icons.chat,
                      title: 'Chat',
                      isSelected: widget.currentRoute == '/chat',
                      onTap: () => _navigateTo(context, const ChatScreen(), '/chat'),
                    ),

                    _buildDrawerItem(
                      context: context,
                      icon: Icons.history,
                      title: 'Chat History',
                      isSelected: widget.currentRoute == '/chat_history',
                      onTap: () => _navigateTo(context, const ChatHistoryScreen(), '/chat_history'),
                    ),

                    _buildDrawerItem(
                      context: context,
                      icon: Icons.settings,
                      title: 'Settings',
                      isSelected: widget.currentRoute == '/settings',
                      onTap: () => _navigateTo(context, const SettingsScreen(), '/settings'),
                    ),

                    _buildDrawerItem(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'About App',
                      isSelected: widget.currentRoute == '/app_details',
                      onTap: () => _navigateTo(context, const AppDetailsScreen(), '/app_details'),
                    ),

                    const Divider(),

                    // Theme toggle
                    SwitchListTile(
                      title: Row(
                        children: [
                          Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                        ],
                      ),
                      value: isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              // Bottom section with logout and version
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // App version
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? theme.colorScheme.primary.withAlpha(26) : null, // 0.1 * 255 = 26
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
