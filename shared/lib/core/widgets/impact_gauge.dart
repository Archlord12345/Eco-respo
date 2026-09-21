import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class ImpactGauge extends StatelessWidget {
  const ImpactGauge({
    super.key,
    required this.percent,
    this.size = 96,
    this.label = '',
  });

  final double percent;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(percent.clamp(0, 1)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
              if (label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: AppColors.textDark),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0, math.pi * 2, false, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.t != t;
}
