import 'package:flutter/material.dart';

class PhoneCrosshairOverlay extends StatelessWidget {
  const PhoneCrosshairOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PhoneCrosshairPainter(), child: Container());
  }
}

class _PhoneCrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint centerDotPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Центр прицела в верхней трети экрана
    final double centerX = size.width / 2;
    final double centerY = size.height / 3;
    final double crosshairSize = 40.0;

    // Рисуем круг
    canvas.drawCircle(Offset(centerX, centerY), crosshairSize, paint);

    // Рисуем внутренний круг
    canvas.drawCircle(Offset(centerX, centerY), crosshairSize / 2, paint);

    // Рисуем горизонтальную линию (слева)
    canvas.drawLine(Offset(centerX - crosshairSize - 10, centerY), Offset(centerX - crosshairSize, centerY), paint);

    // Рисуем горизонтальную линию (справа)
    canvas.drawLine(Offset(centerX + crosshairSize, centerY), Offset(centerX + crosshairSize + 10, centerY), paint);

    // Рисуем вертикальную линию (сверху)
    canvas.drawLine(Offset(centerX, centerY - crosshairSize - 10), Offset(centerX, centerY - crosshairSize), paint);

    // Рисуем вертикальную линию (снизу)
    canvas.drawLine(Offset(centerX, centerY + crosshairSize), Offset(centerX, centerY + crosshairSize + 10), paint);

    // Рисуем центральную точку
    canvas.drawCircle(Offset(centerX, centerY), 4.0, centerDotPaint);
  }

  @override
  bool shouldRepaint(_PhoneCrosshairPainter oldDelegate) => false;
}
