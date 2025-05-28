import 'dart:math';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late List<Animation<double>> _dotAnimations;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation for the dots
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Create staggered animations for each dot
    _dotAnimations = List.generate(3, (index) {
      final begin = index * 0.2;
      final end = begin + 0.6;

      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic))),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Interval(end, min(end + 0.4, 1.0), curve: Curves.easeInCubic))),
          weight: 40,
        ),
      ]).animate(_mainController);
    });

    // Pulse animation for the container
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseController);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar with subtle rotation
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    final rotationValue = sin(_mainController.value * pi * 2) * 0.05;
                    return Transform.rotate(
                      angle: rotationValue,
                      child: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        radius: 16,
                        child: const Icon(
                          Icons.psychology,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Message bubble with animated dots
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? theme.colorScheme.surface.withAlpha(200)
                        : theme.colorScheme.surface.withAlpha(240),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _dotAnimations[index],
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8 + (_dotAnimations[index].value * 8),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(
                                (200 * _dotAnimations[index].value).toInt() + 55
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
