import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceWave extends StatefulWidget {
  final AnimationController animationController;
  final Color color;
  final double size;

  const VoiceWave({
    super.key,
    required this.animationController,
    required this.color,
    this.size = 80.0,
  });

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Create a pulse animation for the container
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animationController, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withAlpha(40),
                  widget.color.withAlpha(10),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
            child: CustomPaint(
              painter: EnhancedVoiceWavePainter(
                animation: widget.animationController,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class EnhancedVoiceWavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  EnhancedVoiceWavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw multiple wave rings with different properties
    for (int i = 0; i < 4; i++) {
      final progress = (animation.value + (i * 0.25)) % 1.0;
      final waveOpacity = (1.0 - progress) * 0.7;

      final paint = Paint()
        ..color = color.withAlpha((waveOpacity * 255).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (i * 0.5);

      // Create a wave effect with sine function
      final waveRadius = radius * (0.4 + (progress * 0.6));
      final path = Path();

      for (int j = 0; j < 360; j += 4) {
        final radians = j * math.pi / 180;
        final waveHeight = 4.0 * math.sin((animation.value * 12) + (i * 2) + (j / 20));
        final x = center.dx + (waveRadius + waveHeight) * math.cos(radians);
        final y = center.dy + (waveRadius + waveHeight) * math.sin(radians);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw inner circle with gradient
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withAlpha(100),
          color.withAlpha(30),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.3));

    canvas.drawCircle(center, radius * 0.3, innerPaint);

    // Draw pulsing dots around the circle
    const dotCount = 8;
    const dotRadius = 3.0;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final dotProgress = (animation.value + (i / dotCount)) % 1.0;
      final dotOpacity = math.sin(dotProgress * math.pi) * 0.8;

      final dotPaint = Paint()
        ..color = color.withAlpha((dotOpacity * 255).toInt())
        ..style = PaintingStyle.fill;

      final dotX = center.dx + (radius * 0.7) * math.cos(angle);
      final dotY = center.dy + (radius * 0.7) * math.sin(angle);

      canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
