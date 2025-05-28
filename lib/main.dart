import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ai_psychologist/screens/chat_screen.dart';
import 'package:ai_psychologist/screens/splash_screen.dart';
import 'package:ai_psychologist/screens/login_screen.dart';
import 'package:ai_psychologist/screens/settings_screen.dart';
import 'package:ai_psychologist/screens/chat_history_screen.dart';
import 'package:ai_psychologist/screens/app_details_screen.dart';
import 'package:ai_psychologist/screens/voice_chat_screen.dart';
import 'package:ai_psychologist/screens/user_dashboard_screen.dart';
import 'package:ai_psychologist/providers/theme_provider.dart';
import 'package:ai_psychologist/providers/chat_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AI Psychologist',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getLightTheme(),
          darkTheme: themeProvider.getDarkTheme(),
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/chat': (context) => const ChatScreen(),
            '/chat_history': (context) => const ChatHistoryScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/app_details': (context) => const AppDetailsScreen(),
            '/voice_chat': (context) => const VoiceChatScreen(),
            '/dashboard': (context) => const UserDashboardScreen(),
          },
        );
      },
    );
  }
}
