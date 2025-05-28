import 'package:flutter/material.dart';
import 'package:ai_psychologist_windows/models/message.dart';
import 'package:intl/intl.dart';

class ChatMessage extends StatelessWidget {
  final Message message;
  final bool animation;

  const ChatMessage({
    super.key,
    required this.message,
    this.animation = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeString = DateFormat('h:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) _buildAvatar(context, isUser),
            const SizedBox(width: 8),
            Flexible(
              child: _buildMessageBubble(context, isUser, timeString),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(context, isUser),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return CircleAvatar(
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.primary,
      radius: 16,
      child: Icon(
        isUser ? Icons.person : Icons.psychology,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isUser, String timeString) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: 'message-${message.timestamp.millisecondsSinceEpoch}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isUser
                ? (isDarkMode ? Colors.blue[800] : const Color(0xFFE1F5FE))
                : (isDarkMode ? Colors.grey[800] : const Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(5),
              bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : (isDarkMode ? Colors.white : Colors.black87),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeString,
                style: TextStyle(
                  color: isUser
                      ? (isDarkMode ? Colors.white70 : Colors.black54)
                      : (isDarkMode ? Colors.white70 : Colors.black54),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
