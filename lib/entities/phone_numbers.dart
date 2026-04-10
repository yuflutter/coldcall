import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/services.dart';

part 'phone_numbers.mapper.dart';

@MappableClass()
class PhoneNumber with PhoneNumberMappable {
  late final String cleanNumber; // используется в качестве уникального ключа
  late final String formattedNumber; // отображение в интерфейсе в соотв. с текущими настройками

  @MappableConstructor()
  PhoneNumber({required this.cleanNumber, required this.formattedNumber});

  PhoneNumber.fromRaw({required String rawNumber}) {
    final conf = di<AppConfig>();
    cleanNumber = conf.cleanPhoneNumber(rawNumber);
    formattedNumber = conf.phoneNumberFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: cleanNumber)).text;
  }

  PhoneNumber.fromDetected({required DetectedPhoneNumber detected})
    : cleanNumber = detected.cleanNumber,
      formattedNumber = detected.formattedNumber;
}

class DetectedPhoneNumber extends PhoneNumber {
  final String rawNumber; // распозналось камерой, или пользователь ввел руками
  final Rect boundingBox;

  DetectedPhoneNumber({required this.rawNumber, required this.boundingBox}) : super.fromRaw(rawNumber: rawNumber);

  bool get isPhoneNumber => di<AppConfig>().isPhoneNumber(cleanNumber);
}
