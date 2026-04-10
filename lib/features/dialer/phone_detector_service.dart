import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PhoneDetectorService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<List<DetectedPhoneNumber>> detectPhones(InputImage image) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(image);
      final List<DetectedPhoneNumber> detectedPhones = [];

      for (TextBlock block in recognizedText.blocks) {
        final String text = block.text;
        final matches = di<AppConfig>().phoneNumberRegex.allMatches(text);

        for (Match match in matches) {
          final String phoneNumber = match.group(0) ?? '';

          final detectedPhone = DetectedPhoneNumber(rawNumber: phoneNumber, boundingBox: block.boundingBox);

          // Проверяем минимальную длину (10 цифр)
          if (detectedPhone.isPhoneNumber) {
            detectedPhones.add(detectedPhone);
          }
        }
      }

      return detectedPhones;
    } catch (e) {
      Log('$runtimeType').err('Error detecting phones: $e', null);
      return [];
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
