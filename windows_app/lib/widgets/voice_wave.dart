import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceWave extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
          ),
          child: CustomPaint(
            painter: VoiceWavePainter(
              animation: animationController,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  VoiceWavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.3 - (i * 0.1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Create a wave effect with sine function
      final waveRadius = radius * (0.6 + (i * 0.2));
      final path = Path();

      for (int j = 0; j < 360; j += 5) {
        final radians = j * math.pi / 180;
        final waveHeight = 5.0 * math.sin((animation.value * 10) + (i * 2) + (j / 30));
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
