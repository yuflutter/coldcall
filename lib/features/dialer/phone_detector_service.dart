import 'package:coldcall/app_config.dart';
import 'package:coldcall/entities/detected_phone.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PhoneDetectorService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<List<DetectedPhone>> detectPhones(InputImage image) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(image);
      final List<DetectedPhone> detectedPhones = [];

      for (TextBlock block in recognizedText.blocks) {
        final String text = block.text;
        final matches = phoneRegex.allMatches(text);

        for (Match match in matches) {
          final String phoneNumber = match.group(0) ?? '';
          final String cleanNumber = _cleanPhoneNumber(phoneNumber);

          // Проверяем минимальную длину (10 цифр)
          if (cleanNumber.length >= 10) {
            detectedPhones.add(DetectedPhone(phoneNumber: phoneNumber, cleanNumber: cleanNumber, boundingBox: block.boundingBox));
          }
        }
      }

      return detectedPhones;
    } catch (e) {
      print('Error detecting phones: $e');
      return [];
    }
  }

  String _cleanPhoneNumber(String phone) {
    // Удаляем все символы кроме цифр и +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Заменяем 8 в начале на +7 для российских номеров
    if (cleaned.startsWith('8') && cleaned.length == 11) {
      cleaned = '+7${cleaned.substring(1)}';
    }

    return cleaned;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
