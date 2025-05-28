import 'package:flutter/material.dart';
import 'package:ai_psychologist/models/message.dart';
import 'package:intl/intl.dart';

class ChatMessage extends StatefulWidget {
  final Message message;
  final bool animation;
  final double textSize;

  const ChatMessage({
    super.key,
    required this.message,
    this.animation = false,
    this.textSize = 16.0,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    // Different slide animations for user and AI messages
    _slideAnimation = Tween<Offset>(
      begin: widget.message.isUser
          ? const Offset(0.3, 0)
          : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Start the animation with a small delay for sequential messages
    if (widget.animation) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final timeString = DateFormat('h:mm a').format(widget.message.timestamp);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Align(
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
              ),
            ),
          ),
        );
      },
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
      tag: 'message-${widget.message.timestamp.millisecondsSinceEpoch}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isUser
                ? (isDarkMode
                    ? Theme.of(context).colorScheme.secondary.withAlpha(204) // 0.8 opacity
                    : Theme.of(context).colorScheme.secondary.withAlpha(38))  // 0.15 opacity
                : (isDarkMode
                    ? Theme.of(context).colorScheme.surface.withAlpha(204)    // 0.8 opacity
                    : Theme.of(context).colorScheme.surface.withAlpha(178)),  // 0.7 opacity
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(5),
              bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message.text,
                style: TextStyle(
                  color: isUser
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : (isDarkMode ? Colors.white : Colors.black87),
                  fontSize: widget.textSize,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      color: isUser
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white70 : Colors.black54),
                      fontSize: 10,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
