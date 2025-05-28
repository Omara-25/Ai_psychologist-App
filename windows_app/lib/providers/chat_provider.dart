import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ai_psychologist_windows/models/message.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  
  static const String apiUrl = 'https://real-time-ai-psychologist-endpoints-production.up.railway.app/chat';
  
  ChatProvider() {
    // Add initial AI message
    _messages.add(
      Message(
        text: "Hello! I'm your AI psychologist. How are you feeling today? Feel free to type or use the microphone to share your thoughts.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
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
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': text,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = Message(
          text: data['response'],
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMessage);
      } else {
        // Handle error
        final aiMessage = Message(
          text: "I'm sorry, I couldn't process your request. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMessage);
      }
    } catch (e) {
      // Handle exception
      final aiMessage = Message(
        text: "I'm sorry, there was an error connecting to the server. Please check your internet connection and try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
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
  }
}
