import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:ai_psychologist_windows/providers/chat_provider.dart';
import 'package:ai_psychologist_windows/providers/theme_provider.dart';
import 'package:ai_psychologist_windows/widgets/chat_message.dart';
import 'package:ai_psychologist_windows/widgets/typing_indicator.dart';
import 'package:ai_psychologist_windows/widgets/voice_wave.dart';
import 'package:ai_psychologist_windows/widgets/theme_selector.dart';

// Windows-specific version of ChatScreen that doesn't use flutter_tts
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeechEnabled = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _isSpeechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          _animationController.reverse();
        }
      },
    );
  }

  void _listen() async {
    if (!_isSpeechEnabled) {
      return;
    }

    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
      _animationController.reverse();
      return;
    }

    setState(() {
      _isListening = true;
    });
    _animationController.forward();

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _textController.text = result.recognizedWords;
          if (result.recognizedWords.trim().isNotEmpty) {
            _handleSubmit(result.recognizedWords);
          }
          setState(() {
            _isListening = false;
          });
          _animationController.reverse();
        }
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available width for title
            final availableWidth = constraints.maxWidth - 120; // Account for actions

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
                    availableWidth > 250 ? 'AI Psychologist (Windows)' : 'AI Psychologist',
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
                    width: 350,
                    height: 400,
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
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Text-to-Speech not available on Windows'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  enabled: false,
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
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8.0),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isListening)
                      VoiceWave(
                        animationController: _animationController,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: _isSpeechEnabled ? _listen : null,
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    if (_textController.text.trim().isNotEmpty) {
                      _handleSubmit(_textController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
