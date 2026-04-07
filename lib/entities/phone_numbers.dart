import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/services.dart';

part 'phone_numbers.mapper.dart';

@MappableClass()
class PhoneNumber with PhoneNumberMappable {
  final String originNumber; // распозналось камерой, или пользователь ввел руками
  late final String cleanNumber; // используется в качестве ключа уникальности
  late final String formattedNumber; // отображение в интерфейсе в соотв. с текущими настройками

  PhoneNumber({required this.originNumber}) {
    cleanNumber = di<AppConfig>().cleanPhoneNumber(originNumber);
    formattedNumber = _formattedPhoneNumber(cleanNumber);
  }

  String _formattedPhoneNumber(String phone) {
    return di<AppConfig>().phoneNumberFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: cleanNumber)).text;
  }

  bool get isPhoneNumber => di<AppConfig>().isPhoneNumber(cleanNumber);
}

class DetectedPhoneNumber extends PhoneNumber {
  final Rect boundingBox;

  DetectedPhoneNumber({required super.originNumber, required this.boundingBox});
}
