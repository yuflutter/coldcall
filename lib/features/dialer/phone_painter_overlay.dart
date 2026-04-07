import 'package:coldcall/entities/phone_numbers.dart';
import 'package:flutter/material.dart';

class PhonePainterOverlay extends CustomPainter {
  final List<DetectedPhoneNumber> detectedPhones;
  final DetectedPhoneNumber? selectedPhone;
  final Size imageSize;
  final Size screenSize;

  PhonePainterOverlay({required this.detectedPhones, this.selectedPhone, required this.imageSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    for (var phone in detectedPhones) {
      final bool isSelected = selectedPhone?.cleanNumber == phone.cleanNumber;

      final Paint paint = Paint()
        ..color = isSelected ? Colors.red : Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 3.0;

      final Rect scaledRect = Rect.fromLTRB(
        phone.boundingBox.left * scaleX,
        phone.boundingBox.top * scaleY,
        phone.boundingBox.right * scaleX,
        phone.boundingBox.bottom * scaleY,
      );

      canvas.drawRect(scaledRect, paint);

      // Рисуем текст номера
      final textSpan = TextSpan(
        text: phone.originNumber,
        style: TextStyle(
          color: isSelected ? Colors.red : Colors.green,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );

      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);

      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledRect.left, scaledRect.top - 20));
    }
  }

  @override
  bool shouldRepaint(PhonePainterOverlay oldDelegate) {
    return detectedPhones != oldDelegate.detectedPhones || selectedPhone != oldDelegate.selectedPhone;
  }
}
