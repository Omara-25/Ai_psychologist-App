import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ai_psychologist/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  static const String apiUrl = 'https://real-time-ai-psychologist-endpoints-production.up.railway.app/chat';
  static const String _storageKey = 'chat_history';

  ChatProvider() {
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonData = jsonDecode(jsonString) as List;
        final loadedMessages = jsonData.map((item) => Message.fromJson(item as Map<String, dynamic>)).toList();

        if (loadedMessages.isNotEmpty) {
          _messages.addAll(loadedMessages);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }

    // If no history or error, add initial message
    _addInitialMessage();
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonData));
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  void _addInitialMessage() {
    _messages.add(
      Message(
        text: "Hello! I'm your AI psychologist. How are you feeling today? Feel free to type or use the microphone to share your thoughts.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    _saveChatHistory();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = Message(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Sending request to API: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': text,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('API request timed out');
      });

      debugPrint('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('API response data: $data');

          if (data.containsKey('response')) {
            final aiMessage = Message(
              text: data['response'],
              isUser: false,
              timestamp: DateTime.now(),
            );
            _messages.add(aiMessage);
          } else {
            throw Exception('Invalid response format: missing "response" field');
          }
        } catch (e) {
          debugPrint('Error parsing API response: $e');
          final aiMessage = Message(
            text: "I'm sorry, I received an invalid response from the server. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          );
          _messages.add(aiMessage);
        }
      } else {
        // Handle error
        debugPrint('API error: ${response.body}');
        final aiMessage = Message(
          text: "I'm sorry, I couldn't process your request. Please try again later. (Status: ${response.statusCode})",
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMessage);
      }
    } catch (e) {
      // Handle exception
      debugPrint('Exception during API call: $e');
      final aiMessage = Message(
        text: "I'm sorry, there was an error connecting to the server. Please check your internet connection and try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
    } finally {
      _isLoading = false;
      notifyListeners();

      // Save chat history after receiving response
      _saveChatHistory();
    }
  }

  void clearChat() {
    _messages.clear();
    // Add initial AI message again
    _messages.add(
      Message(
        text: "Hello! I'm your AI psychologist. How are you feeling today? Feel free to type or use the microphone to share your thoughts.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    // Save the cleared chat
    _saveChatHistory();
  }
}
