import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_psychologist/providers/theme_provider.dart';
import 'package:ai_psychologist/widgets/theme_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _textToSpeechEnabled = true;
  bool _speechRecognitionEnabled = true;
  double _speechRate = 0.5;
  double _textSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _textToSpeechEnabled = prefs.getBool('textToSpeechEnabled') ?? true;
        _speechRecognitionEnabled = prefs.getBool('speechRecognitionEnabled') ?? true;
        _speechRate = prefs.getDouble('speechRate') ?? 0.5;
        _textSize = prefs.getDouble('textSize') ?? 16.0;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('textToSpeechEnabled', _textToSpeechEnabled);
      await prefs.setBool('speechRecognitionEnabled', _speechRecognitionEnabled);
      await prefs.setDouble('speechRate', _speechRate);
      await prefs.setDouble('textSize', _textSize);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // First try to pop the current screen
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If can't pop, navigate to chat screen using named route
              Navigator.of(context).pushReplacementNamed('/chat');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            _buildSectionHeader(context, 'Appearance'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Dark mode toggle
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return SwitchListTile(
                        title: Row(
                          children: [
                            Icon(
                              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            const Text('Dark Mode'),
                          ],
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: theme.colorScheme.primary,
                      );
                    },
                  ),
                  const Divider(),
                  // Text size slider
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: const Text('Text Size'),
                    subtitle: Slider(
                      value: _textSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 6,
                      label: _textSize.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _textSize = value;
                        });
                        _saveSettings();
                      },
                    ),
                    trailing: Text(
                      '${_textSize.round()}',
                      style: TextStyle(
                        fontSize: _textSize,
                      ),
                    ),
                  ),
                  // Color theme
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Color Theme'),
                    subtitle: const Text('Choose your preferred color theme'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Theme'),
                          content: const SizedBox(
                            width: 300,
                            height: 200,
                            child: ThemeSelector(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Accessibility section
            _buildSectionHeader(context, 'Accessibility'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Text-to-speech toggle
                  SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        const Text('Text-to-Speech'),
                      ],
                    ),
                    subtitle: const Text('AI responses will be spoken aloud'),
                    value: _textToSpeechEnabled,
                    onChanged: (value) {
                      setState(() {
                        _textToSpeechEnabled = value;
                      });
                      _saveSettings();
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  // Speech rate slider (only visible if TTS is enabled)
                  if (_textToSpeechEnabled)
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: const Text('Speech Rate'),
                      subtitle: Slider(
                        value: _speechRate,
                        min: 0.25,
                        max: 1.0,
                        divisions: 6,
                        label: _getSpeechRateLabel(_speechRate),
                        onChanged: (value) {
                          setState(() {
                            _speechRate = value;
                          });
                          _saveSettings();
                        },
                      ),
                      trailing: Text(_getSpeechRateLabel(_speechRate)),
                    ),
                  const Divider(),
                  // Speech recognition toggle
                  SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        const Text('Speech Recognition'),
                      ],
                    ),
                    subtitle: const Text('Enable voice input for messages'),
                    value: _speechRecognitionEnabled,
                    onChanged: (value) {
                      setState(() {
                        _speechRecognitionEnabled = value;
                      });
                      _saveSettings();
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),

            // About section
            _buildSectionHeader(context, 'About'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.code,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Developer'),
                    subtitle: const Text('AI Psychologist Team'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getSpeechRateLabel(double rate) {
    if (rate <= 0.3) return 'Slow';
    if (rate <= 0.5) return 'Normal';
    if (rate <= 0.75) return 'Fast';
    return 'Very Fast';
  }
}
