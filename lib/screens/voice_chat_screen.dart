import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ai_psychologist/providers/chat_provider.dart';
import 'package:ai_psychologist/widgets/voice_wave.dart';
import 'package:ai_psychologist/widgets/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isSpeechEnabled = false;
  bool _showChatHistory = false;
  String _recognizedText = '';
  String _lastResponse = '';

  // Voice settings
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _selectedVoice = '';
  List<Map<String, String>> _availableVoices = [];
  String _selectedLanguage = 'en-US';
  List<String> _availableLanguages = [];

  late AnimationController _animationController;

  // Chat provider reference
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize chat provider
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      // Check and request microphone permission
      final microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isDenied) {
          debugPrint('Microphone permission denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission is required for voice chat'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      _isSpeechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            _animationController.reverse();

            // Only send if we have recognized text
            if (_recognizedText.isNotEmpty) {
              debugPrint('Sending recognized text: $_recognizedText');
              _sendMessage(_recognizedText);
              setState(() {
                _recognizedText = '';
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
          _animationController.reverse();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: $error'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );

      if (!_isSpeechEnabled) {
        debugPrint('Speech recognition not available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition is not available on this device'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize speech recognition: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _initTts() async {
    // Load saved settings or use defaults
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechRate = prefs.getDouble('speechRate') ?? 0.5;
      _pitch = prefs.getDouble('pitch') ?? 1.0;
      _volume = prefs.getDouble('volume') ?? 1.0;
      _selectedLanguage = prefs.getString('language') ?? 'en-US';
      _selectedVoice = prefs.getString('voice') ?? '';
    });

    // Apply settings
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    // Load available languages
    try {
      final languages = await _flutterTts.getLanguages;
      setState(() {
        _availableLanguages = List<String>.from(languages);
      });
    } catch (e) {
      debugPrint('Failed to get languages: $e');
      setState(() {
        _availableLanguages = ['en-US', 'en-GB', 'fr-FR', 'de-DE', 'es-ES', 'it-IT'];
      });
    }

    // Load available voices
    try {
      final voices = await _flutterTts.getVoices;
      setState(() {
        _availableVoices = List<Map<String, String>>.from(voices);

        // If no voice is selected, try to select a default one
        if (_selectedVoice.isEmpty && _availableVoices.isNotEmpty) {
          // Try to find a voice for the selected language
          final voiceForLanguage = _availableVoices.firstWhere(
            (voice) => voice['locale'] == _selectedLanguage,
            orElse: () => _availableVoices.first,
          );
          _selectedVoice = voiceForLanguage['name'] ?? '';
          if (_selectedVoice.isNotEmpty) {
            _flutterTts.setVoice({"name": _selectedVoice, "locale": _selectedLanguage});
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to get voices: $e');
    }
  }

  void _listen() async {
    if (!_isSpeechEnabled) {
      debugPrint('Speech recognition not enabled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // If already listening, stop
    if (_isListening) {
      debugPrint('Stopping speech recognition');
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      _animationController.reverse();

      // If we have text, send it
      if (_recognizedText.isNotEmpty) {
        debugPrint('Sending recognized text after stopping: $_recognizedText');
        _sendMessage(_recognizedText);
        setState(() {
          _recognizedText = '';
        });
      }
      return;
    }

    // If speaking, stop first
    if (_isSpeaking) {
      debugPrint('Stopping TTS before listening');
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    }

    // Start listening
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });
    _animationController.forward();

    try {
      debugPrint('Starting speech recognition');
      await _speech.listen(
        onResult: (result) {
          debugPrint('Speech recognition result: ${result.recognizedWords}');
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
      _animationController.reverse();

      // Check if widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting speech recognition: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    debugPrint('Sending message: $text');

    // Use the stored chat provider reference
    await _chatProvider.sendMessage(text);

    // Scroll to bottom after message is sent
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Wait for the response with a timeout
    int attempts = 0;
    const maxAttempts = 30; // 15 seconds timeout (30 * 500ms)

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      attempts++;

      // Check if we have a response
      if (!_chatProvider.isLoading &&
          _chatProvider.messages.isNotEmpty &&
          !_chatProvider.messages.last.isUser) {

        final response = _chatProvider.messages.last.text;

        // Only process if this is a new response
        if (response != _lastResponse) {
          _lastResponse = response;
          debugPrint('Speaking response: $response');
          _speakResponse(response);

          // Scroll to bottom after receiving response
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }

        // Cancel the timer once we've processed the response
        timer.cancel();
      }

      // Cancel after timeout
      if (attempts >= maxAttempts) {
        timer.cancel();
        debugPrint('Timeout waiting for response');
      }
    });
  }

  Future<void> _speakResponse(String text) async {
    // Stop any current speech before starting new one
    await _flutterTts.stop();

    setState(() {
      _isSpeaking = true;
    });

    // Apply current voice settings before speaking
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    // Set voice if available
    if (_selectedVoice.isNotEmpty) {
      await _flutterTts.setVoice({"name": _selectedVoice, "locale": _selectedLanguage});
    }

    await _flutterTts.speak(text);
  }

  // Save voice settings to SharedPreferences
  Future<void> _saveVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setDouble('pitch', _pitch);
    await prefs.setDouble('volume', _volume);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('voice', _selectedVoice);
  }

  // Show voice settings dialog
  void _showVoiceSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Voice Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Speech rate slider
                    const Text('Speech Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _speechRate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: _getSpeechRateLabel(_speechRate),
                      onChanged: (value) {
                        setDialogState(() {
                          _speechRate = value;
                        });
                        setState(() {
                          _speechRate = value;
                        });
                      },
                    ),
                    Text(_getSpeechRateLabel(_speechRate)),
                    const SizedBox(height: 16),

                    // Pitch slider
                    const Text('Pitch', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: _pitch.toStringAsFixed(1),
                      onChanged: (value) {
                        setDialogState(() {
                          _pitch = value;
                        });
                        setState(() {
                          _pitch = value;
                        });
                      },
                    ),
                    Text(_getPitchLabel(_pitch)),
                    const SizedBox(height: 16),

                    // Volume slider
                    const Text('Volume', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _volume,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: '${(_volume * 100).round()}%',
                      onChanged: (value) {
                        setDialogState(() {
                          _volume = value;
                        });
                        setState(() {
                          _volume = value;
                        });
                      },
                    ),
                    Text('${(_volume * 100).round()}%'),
                    const SizedBox(height: 16),

                    // Language dropdown
                    if (_availableLanguages.isNotEmpty) ...[
                      const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedLanguage,
                        items: _availableLanguages.map((language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(_getLanguageDisplayName(language)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              _selectedLanguage = value;
                              // Reset voice when language changes
                              _selectedVoice = '';
                            });
                            setState(() {
                              _selectedLanguage = value;
                              _selectedVoice = '';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Voice dropdown (if available)
                    if (_availableVoices.isNotEmpty) ...[
                      const Text('Voice', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedVoice.isNotEmpty ? _selectedVoice : null,
                        hint: const Text('Select a voice'),
                        items: _availableVoices
                            .where((voice) => voice['locale'] == _selectedLanguage)
                            .map((voice) {
                          final name = voice['name'] ?? 'Unknown';
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              _selectedVoice = value;
                            });
                            setState(() {
                              _selectedVoice = value;
                            });
                          }
                        },
                      ),
                    ],

                    // Test voice button
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Test Voice'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _testVoice();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveVoiceSettings();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice settings saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Test the current voice settings
  Future<void> _testVoice() async {
    setState(() {
      _isSpeaking = true;
    });

    // Apply current settings
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    if (_selectedVoice.isNotEmpty) {
      await _flutterTts.setVoice({"name": _selectedVoice, "locale": _selectedLanguage});
    }

    await _flutterTts.speak("This is a test of the current voice settings.");
  }

  // Helper methods for labels
  String _getSpeechRateLabel(double rate) {
    if (rate <= 0.3) return 'Slow';
    if (rate <= 0.6) return 'Normal';
    if (rate <= 0.8) return 'Fast';
    return 'Very Fast';
  }

  String _getPitchLabel(double pitch) {
    if (pitch <= 0.8) return 'Low';
    if (pitch <= 1.2) return 'Normal';
    if (pitch <= 1.6) return 'High';
    return 'Very High';
  }

  String _getLanguageDisplayName(String code) {
    final languageNames = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'fr-FR': 'French',
      'de-DE': 'German',
      'es-ES': 'Spanish',
      'it-IT': 'Italian',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
      'zh-CN': 'Chinese (Simplified)',
      'ru-RU': 'Russian',
    };

    return languageNames[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Chat'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Voice settings button
          IconButton(
            icon: const Icon(Icons.settings_voice),
            tooltip: 'Voice Settings',
            onPressed: () {
              _showVoiceSettingsDialog();
            },
          ),
          // Toggle between voice-only and chat view
          IconButton(
            icon: Icon(_showChatHistory ? Icons.mic : Icons.chat),
            tooltip: _showChatHistory ? 'Voice Only' : 'Show Chat History',
            onPressed: () {
              setState(() {
                _showChatHistory = !_showChatHistory;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              isDarkMode
                  ? theme.colorScheme.surface.withAlpha(220)
                  : theme.colorScheme.primary.withAlpha(15),
            ],
          ),
        ),
        child: Column(
          children: [
            // Show either chat history or voice interface based on toggle
            _showChatHistory
                ? Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, chatProvider, _) {
                        return Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.black.withAlpha(76) // 0.3 * 255 = 76
                                : Colors.white.withAlpha(178), // 0.7 * 255 = 178
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            itemCount: chatProvider.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatProvider.messages[index];
                              return ChatMessage(
                                message: message,
                                animation: index == chatProvider.messages.length - 1,
                                textSize: 16.0,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                : Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Voice wave animation
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              VoiceWave(
                                animationController: _animationController,
                                color: _isListening
                                    ? theme.colorScheme.primary
                                    : (_isSpeaking
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.primary.withAlpha(100)),
                                size: 200,
                              ),
                              Icon(
                                _isListening
                                    ? Icons.mic
                                    : (_isSpeaking ? Icons.volume_up : Icons.mic_none),
                                size: 50,
                                color: _isListening || _isSpeaking
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withAlpha(150),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Status text
                          Text(
                            _isListening
                                ? 'Listening...'
                                : (_isSpeaking
                                    ? 'Speaking...'
                                    : 'Tap the microphone to speak'),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          // Recognized text
                          if (_recognizedText.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _recognizedText,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
            // Bottom controls
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'back_to_chat',
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    FloatingActionButton.large(
                      heroTag: 'voice_button',
                      onPressed: _listen,
                      backgroundColor: _isListening
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.white
                            : theme.colorScheme.primary,
                        size: 36,
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'stop_speaking',
                      onPressed: _isSpeaking
                          ? () {
                              _flutterTts.stop();
                              setState(() {
                                _isSpeaking = false;
                              });
                            }
                          : null,
                      backgroundColor: _isSpeaking
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.surface.withAlpha(150),
                      child: Icon(
                        Icons.volume_off,
                        color: _isSpeaking
                            ? Colors.white
                            : theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
