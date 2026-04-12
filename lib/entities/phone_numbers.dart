import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/entities/syncable.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/services.dart';

part 'phone_numbers.mapper.dart';

// В качестве id используется cleanNumber, то есть номер, очищенный от разделителей и с заменой 8 на +7
@MappableClass()
class PhoneNumber extends Syncable with PhoneNumberMappable {
  late final String formattedNumber; // отображение в интерфейсе в соотв. с текущими настройками
  String? _name;

  @MappableConstructor()
  PhoneNumber({required super.id, required this.formattedNumber, String? name}) : _name = name;

  PhoneNumber.fromRaw({required String rawNumber}) : super(id: di<AppConfig>().cleanPhoneNumber(rawNumber)) {
    formattedNumber = di<AppConfig>().phoneNumberFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: id)).text;
  }

  PhoneNumber.fromDetected({required DetectedPhoneNumber detected}) : formattedNumber = detected.formattedNumber, super(id: detected.id);

  String get cleanNumber => id;

  String? get name => _name;
  void updateName(String name) => update(() => _name = name);

  @override
  void mergeFrom(covariant PhoneNumber other) {
    super.mergeFrom(other);
    _name = other.name ?? _name;
  }
}

// Этот класс не сериализуется и не синхронизируется, наследование сделал чтобы упростить вызов DialerVm из разных мест
class DetectedPhoneNumber extends PhoneNumber {
  final String rawNumber; // распозналось камерой, или пользователь ввел руками
  final Rect boundingBox;

  DetectedPhoneNumber({required this.rawNumber, required this.boundingBox}) : super.fromRaw(rawNumber: rawNumber);

  bool get isPhoneNumber => di<AppConfig>().isPhoneNumber(id);

  @override
  void mergeFrom(covariant DetectedPhoneNumber other) => super.mergeFrom(other);
}
