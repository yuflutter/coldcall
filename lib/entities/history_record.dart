import 'dart:math';
import 'dart:ui';

import 'package:coldcall/core/dart_mappable_settings.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/entities/syncable.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:path_provider/path_provider.dart';

part 'history_record.mapper.dart';

@MappableClass()
class HistoryRecord extends Syncable with HistoryRecordMappable {
  // Обрубаем ссылку при сериализации (избегаем рекурсии), но к сожалению при любом copyWith поле тоже пропадает,
  // но мы copyWith в этом классе не используем, а просто пишем в поля через методы updateXXX.
  @MappableField(hook: NullMappableFieldHook())
  // не делаем final по двум причинам:
  // 1) при создании HistoryRecord с пустым Deal - объект Deal создается позже на основании полей HistoryRecord
  // 2) при слиянии двух дел в одно (синхронизация по интервалам) - поле deal у записи может перезаписываться
  Deal? deal;
  final DateTime startTime;
  final Duration duration;
  // Сериализуем только ID, объектную ссылку восстанавливаем при десериализации
  @MappableField(hook: NullMappableFieldHook())
  PhoneNumber? _phoneNumber; // обновляется только при синхронизации-слиянии
  String? _phoneNumberId;
  String? _audioFileName; // обновляется только при синхронизации-слиянии
  String? _textTranscription; // обновляется только при синхронизации-слиянии
  String? _note;

  @MappableConstructor()
  HistoryRecord({
    required super.id,
    required this.deal,
    required this.startTime,
    required this.duration,
    final PhoneNumber? phoneNumber,
    final String? phoneNumberId,
    final String? audioFileName,
    final String? textTranscription,
    final String? note,
    super.deleted,
    super.lastModified,
  }) : _phoneNumberId = phoneNumberId,
       _phoneNumber = phoneNumber,
       _audioFileName = audioFileName,
       _textTranscription = textTranscription,
       _note = note;

  factory HistoryRecord.manually({
    final Deal? deal,
    required final DateTime startTime,
    required final Duration duration,
    final PhoneNumber? phoneNumber,
    final String? audioFileName,
    final String? textTranscription,
    final String? note,
  }) {
    final record = HistoryRecord(
      id: null,
      deal: deal,
      startTime: startTime,
      duration: duration,
      phoneNumber: phoneNumber,
      phoneNumberId: phoneNumber?.id,
      audioFileName: audioFileName,
      textTranscription: textTranscription,
      note: note,
    );
    record.deal ??= record._createDealFromThis();
    record.deal!.addRecord(record); // здесь происходит обновление _lastModified у Deal
    return record;
  }

  // При ручном создании первой записи - создаем дело на основе полей записи
  Deal _createDealFromThis() => Deal(
    id: id,
    created: startTime,
    lastModified: startTime,
    title: (textTranscription != null)
        ? 'аудиозапись\n${textTranscription!.substring(0, min(100, textTranscription!.length))}...'
        : (phoneNumber != null)
        ? 'исходящий\n${phoneNumber!.formattedNumber}'
        : startTime.toString(),
  );

  // Нормализуем ссылку на номер телефона при десериализации или ручном создании записи
  void normalizePhoneNumber(SyncableMap<PhoneNumber> phoneBook) {
    // восстановление ссылки после десериализации
    if (_phoneNumber == null && _phoneNumberId != null) {
      _phoneNumber = phoneBook.getById(_phoneNumberId!);

      // ручное создание из диалера
    } else if (_phoneNumber != null) {
      final phone = phoneBook.getById(_phoneNumber!.id);
      if (phone == null) {
        phoneBook.add(_phoneNumber!);
      } else {
        phone.mergeFrom(_phoneNumber!);
        _phoneNumber = phone;
      }
      _phoneNumberId = _phoneNumber!.id;
    }
  }

  PhoneNumber? get phoneNumber => _phoneNumber;

  String? get audioFileName => _audioFileName;
  Future<String>? audioFilePath() async {
    final path = (await getApplicationDocumentsDirectory()).path;
    return '$path/$_audioFileName';
  }

  String? get textTranscription => _textTranscription;

  String? get note => _note;
  void updateNote(String note) => update(() => _note = note);

  // Обновляем lastModified и у родителя
  @override
  void update(VoidCallback? updater, {bool raw = false}) {
    super.update(updater, raw: raw);
    if (deal != null && !raw) deal!.update(null);
  }

  @override
  void mergeFrom(covariant HistoryRecord other) {
    super.mergeFrom(other);

    _phoneNumber = other.phoneNumber ?? _phoneNumber;
    _audioFileName = other.audioFileName ?? _audioFileName;
    _textTranscription = other.textTranscription ?? _textTranscription;
    _note = other.note ?? _note;
  }

  /// Вычисляет процент перекрытия интервалов, используется при merge звонка и аудиозаписи,
  /// которые создаются на разных устройствах, но на самом деле относятся к одному событию.
  bool isIntervalsOverlapped(HistoryRecord other) {
    // сливаем только параллельную запись со звонком, но не два звонка и не две записи
    if (((phoneNumber == null) == (other.phoneNumber == null)) || ((audioFileName == null) == (other.audioFileName == null))) {
      return false;
    }

    final start1 = startTime;
    final start2 = other.startTime;
    final end1 = start1.add(duration);
    final end2 = start2.add(other.duration);

    // Находим границы пересечения
    final overlapStart = start1.isAfter(start2) ? start1 : start2;
    final overlapEnd = end1.isBefore(end2) ? end1 : end2;

    // Длительность пересечения в миллисекундах
    final overlapMs = overlapEnd.difference(overlapStart).inMilliseconds;

    if (overlapMs <= 0) return false;

    // Общий охват обоих интервалов (Total Union)
    final totalStart = start1.isBefore(start2) ? start1 : start2;
    final totalEnd = end1.isAfter(end2) ? end1 : end2;
    final totalMs = totalEnd.difference(totalStart).inMilliseconds;

    final res = (overlapMs / totalMs) * 100;
    Log('$runtimeType').inf('calculateOverlapPercentage: $res %');

    return (res >= 70);
  }
}
