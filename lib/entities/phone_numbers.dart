import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/entities/syncable.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/services.dart';

part 'phone_numbers.mapper.dart';

@MappableClass()
class PhoneNumber extends Syncable with PhoneNumberMappable {
  late final String cleanNumber; // используется в качестве уникального ключа
  late final String formattedNumber; // отображение в интерфейсе в соотв. с текущими настройками
  String? _name;

  @MappableConstructor()
  PhoneNumber({required this.cleanNumber, required this.formattedNumber, String? name}) : _name = name, super(id: cleanNumber);

  PhoneNumber.fromRaw({required String rawNumber}) {
    final conf = di<AppConfig>();
    cleanNumber = conf.cleanPhoneNumber(rawNumber);
    formattedNumber = conf.phoneNumberFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: cleanNumber)).text;
  }

  PhoneNumber.fromDetected({required DetectedPhoneNumber detected})
    : cleanNumber = detected.cleanNumber,
      formattedNumber = detected.formattedNumber;

  String? get name => _name;
  void updateName(String name) => update(() => _name = name);

  @override
  void mergeFrom(covariant PhoneNumber other) {
    super.mergeFrom(other);
    _name = other.name;
  }
}

// Этот класс не сериализуется и не синхронизируется, наследование сделал чтобы упростить вызов DialerVm из разных мест
class DetectedPhoneNumber extends PhoneNumber {
  final String rawNumber; // распозналось камерой, или пользователь ввел руками
  final Rect boundingBox;

  DetectedPhoneNumber({required this.rawNumber, required this.boundingBox}) : super.fromRaw(rawNumber: rawNumber);

  bool get isPhoneNumber => di<AppConfig>().isPhoneNumber(cleanNumber);

  @override
  void mergeFrom(covariant DetectedPhoneNumber other) => super.mergeFrom(other);
}
