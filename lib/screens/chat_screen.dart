import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ai_psychologist/providers/chat_provider.dart';
import 'package:ai_psychologist/providers/theme_provider.dart';
import 'package:ai_psychologist/widgets/chat_message.dart';
import 'package:ai_psychologist/widgets/typing_indicator.dart';
import 'package:ai_psychologist/widgets/voice_wave.dart';
import 'package:ai_psychologist/widgets/theme_selector.dart';
import 'package:ai_psychologist/widgets/app_drawer.dart';
import 'package:ai_psychologist/screens/voice_chat_screen.dart';
import 'package:ai_psychologist/screens/settings_screen.dart';
import 'package:ai_psychologist/screens/chat_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_psychologist/utils/page_transitions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isSpeechEnabled = false;
  bool _isTextToSpeechEnabled = true;
  double _speechRate = 0.5;
  double _textSize = 16.0;
  String _lastSpokenMessageId = ''; // Track last spoken message to avoid repeats
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSpeech();
    _initTts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false);
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isTextToSpeechEnabled = prefs.getBool('textToSpeechEnabled') ?? true;
        _speechRate = prefs.getDouble('speechRate') ?? 0.5;
        _textSize = prefs.getDouble('textSize') ?? 16.0;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _flutterTts.stop();
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
                content: Text('Microphone permission is required for voice input'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      debugPrint('Initializing speech recognition...');
      _isSpeechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            _animationController.reverse();
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
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      debugPrint('Speech recognition initialized: $_isSpeechEnabled');

      // Update UI to reflect speech status
      if (mounted) {
        setState(() {
          // Force UI update
        });
      }

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
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS completed');
    });
  }

  void _listen() async {
    if (!_isSpeechEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_isListening) {
      debugPrint('Stopping speech recognition');
      _speech.stop();
      setState(() {
        _isListening = false;
      });
      _animationController.reverse();
      return;
    }

    setState(() {
      _isListening = true;
      // Clear the text field when starting to listen
      _textController.clear();
    });
    _animationController.forward();

    try {
      debugPrint('Starting speech recognition');
      await _speech.listen(
        onResult: (result) {
          debugPrint('Speech result: ${result.recognizedWords}, final: ${result.finalResult}');

          // Update the text field with the recognized words
          setState(() {
            _textController.text = result.recognizedWords;
          });

          // If this is the final result, automatically send the message
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            debugPrint('Final result detected, sending message: ${result.recognizedWords}');
            _handleSubmit(result.recognizedWords);

            setState(() {
              _isListening = false;
            });
            _animationController.reverse();
          }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting speech recognition: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleSubmit(String text) {
    _textController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(text);

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
  }

  void _speakLatestMessage() {
    if (!_isTextToSpeechEnabled) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.messages.isNotEmpty) {
      final latestMessage = chatProvider.messages.last;
      if (!latestMessage.isUser) {
        // Create a unique ID for this message based on timestamp and text
        final messageId = '${latestMessage.timestamp.millisecondsSinceEpoch}_${latestMessage.text.hashCode}';

        // Only speak if this is a new message we haven't spoken before
        if (messageId != _lastSpokenMessageId) {
          _lastSpokenMessageId = messageId;
          // Stop any current speech before starting new one
          _flutterTts.stop();
          _flutterTts.speak(latestMessage.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/chat'),
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available width for title
            final availableWidth = constraints.maxWidth - 120; // Account for drawer button and actions

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'AI Psychologist',
                    style: TextStyle(
                      fontSize: availableWidth > 200 ? 20 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Color theme selector
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Change Color Theme',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Theme'),
                  content: const SizedBox(
                    width: 300,
                    height: 300,
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
          // More options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              // Theme toggle
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: isDarkMode ? Colors.amber : Colors.indigo,
                  ),
                  title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                ),
              ),
              const PopupMenuDivider(),
              // New chat
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New Chat'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<ChatProvider>(context, listen: false).clearChat();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Started a new chat'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              // Chat history
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Chat History'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      CustomPageTransition(
                        child: const ChatHistoryScreen(),
                        type: PageTransitionType.rightToLeft,
                        curve: Curves.easeInOut,
                      ),
                    );
                  },
                ),
              ),
              // Settings
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      CustomPageTransition(
                        child: const SettingsScreen(),
                        type: PageTransitionType.rightToLeft,
                        curve: Curves.easeInOut,
                      ),
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              // Custom popup menu item for Text-to-Speech toggle
              PopupMenuItem(
                // Disable auto-dismiss when tapping this item
                enabled: true,
                // Use a custom tap handler that doesn't close the menu
                onTap: () {
                  // This prevents the menu from closing
                  // We'll manually handle the state change
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _isTextToSpeechEnabled = !_isTextToSpeechEnabled;
                      if (!_isTextToSpeechEnabled) {
                        _flutterTts.stop();
                      }
                    });
                    // Save setting
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setBool('textToSpeechEnabled', _isTextToSpeechEnabled);
                    });
                  });
                },
                child: Row(
                  children: [
                    // Custom checkbox that doesn't handle its own taps
                    Checkbox(
                      value: _isTextToSpeechEnabled,
                      onChanged: null, // We handle changes in the parent
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Text-to-Speech'),
                  ],
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Clear Chat'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<ChatProvider>(context, listen: false).clearChat();
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About App'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    // Use named route for consistent navigation
                    Navigator.of(context).pushNamed('/app_details');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  // Speak the latest message when it arrives
                  if (chatProvider.messages.isNotEmpty &&
                      !chatProvider.messages.last.isUser &&
                      !chatProvider.isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _speakLatestMessage();
                    });
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length) {
                        // Show typing indicator at the end if loading
                        return const TypingIndicator();
                      }

                      final message = chatProvider.messages[index];
                      return ChatMessage(
                        message: message,
                        animation: true,
                        textSize: _textSize,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type or tap mic to speak...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Action buttons container - more compact
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Voice chat button with animation
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isListening)
                              VoiceWave(
                                animationController: _animationController,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            // Show a small badge to indicate auto-send
                            if (_isListening)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                size: 20,
                              ),
                              onPressed: _isSpeechEnabled ? _listen : null,
                              tooltip: 'Speak to send message automatically',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Full voice chat mode button - always enabled
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          icon: const Icon(Icons.headset_mic, size: 20),
                          color: Theme.of(context).colorScheme.secondary,
                          tooltip: 'Voice chat mode',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              CustomPageTransition(
                                child: const VoiceChatScreen(),
                                type: PageTransitionType.downToUp,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                          },
                        ),
                      ),
                      // Send button
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Send message',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () {
                            if (_textController.text.trim().isNotEmpty) {
                              _handleSubmit(_textController.text);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
