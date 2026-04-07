import 'package:coldcall/core/dart_mappable_settings.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

part '_all_syncable_entities.mapper.dart';

// Принял спорное архитектурное решение, что объекты Deal и HistoryRecord будут мутабельными.
// Не хотелось заморачиваться с заменой объектов в полносвязном дереве.
// Плюс теперь почти вся логика merge инкапсулирована внутри сущностей.
// Пришлось запихать несколько классов в один файл, так как в дарте отсутствует protected, а хотелось надежности.

// ---------------------------------------------------------------------------------------------

abstract class Syncable {
  final int id;
  final DateTime created;
  bool _deleted;
  DateTime _lastModified;

  Syncable({final int? id, final DateTime? created, final bool? deleted, final DateTime? lastModified})
    : id = id ?? DateTime.now().microsecondsSinceEpoch,
      created = created ?? DateTime.now(),
      _deleted = deleted ?? false,
      _lastModified = lastModified ?? DateTime.now();

  bool get deleted => _deleted;
  void markDeleted() => _update(() => _deleted = true);

  DateTime get lastModified => _lastModified;

  /// использовать во всех потомках при ручном обновлении полей
  void _update([VoidCallback? update]) {
    update?.call();
    _lastModified = DateTime.now();
  }

  /// Используется стратегия Last Write Wins для всех полей
  @mustCallSuper
  void mergeFrom(Syncable remote) {
    if (remote.lastModified.isAfter(lastModified)) {
      _deleted = remote.deleted;
    }
  }
}

// ---------------------------------------------------------------------------------------------

@MappableClass()
class Deal extends Syncable with DealMappable {
  String _title;
  final List<HistoryRecord> _records;

  Deal({super.id, super.created, required final String title, final List<HistoryRecord>? records, super.deleted, super.lastModified})
    : _title = title,
      _records = records ?? [] {
    for (var r in _records) {
      r.deal = this; // восстанавливаем ссылку, обрубленную сериализатором
    }
  }

  String get title => _title;
  void updateTitle(String title) => _update(() => _title = title);

  Iterable<HistoryRecord> get records => _records.where((e) => !e.deleted); // возвращаем итератор, что не так надежно, но производительно
  void addRecord(HistoryRecord record) => _update(() => _records.add(record));
  void removeRecord(HistoryRecord record) => _update(() => _records.remove(record));

  bool get hasCalls => records.any((r) => r.phoneNumber != null);
  bool get hasAudios => records.any((r) => r.audioFileName != null);
  String? get lastPhoneNumber => records.firstWhereOrNull((r) => r.phoneNumber != null)?.phoneNumber;

  @override
  void mergeFrom(covariant Deal remote) {
    super.mergeFrom(remote);

    if (remote.lastModified.isAfter(lastModified)) {
      _title = remote.title;
    }

    for (final remoteRecord in remote.records) {
      // ищем запись по ID
      var localRecord = records.firstWhereOrNull((local) => local.id == remoteRecord.id);

      // обновляем поля
      if (localRecord != null) {
        localRecord.mergeFrom(remoteRecord);
        continue;
      }

      // Ищем запись с приблизительно совпадающими интервалами
      localRecord = records.firstWhereOrNull((e) => e.isIntervalsOverlapped(remoteRecord));

      // объединяем две записи в одну
      if (localRecord != null) {
        if (localRecord.lastModified.isAfter(remoteRecord.lastModified)) {
          localRecord.mergeFrom(remoteRecord);
        } else {
          remoteRecord.mergeFrom(localRecord);
          _records.add(remoteRecord..deal = this);
          localRecord.markDeleted();
        }
        continue;
      }

      // добавляем новую запись
      if (localRecord == null) {
        _records.add(remoteRecord);
      }
    }
  }
}

// ---------------------------------------------------------------------------------------------

@MappableClass()
class HistoryRecord extends Syncable with HistoryRecordMappable {
  // избегаем рекурсии при сериализации, к сожалению при любом copyWith поле тоже пропадает,
  // но мы copyWith нигде не используем, а просто пишем в поля через методы updateXXX.
  @MappableField(hook: NullMappableFieldHook())
  // не делаем final по двум причинам:
  // 1) при создании HistoryRecord с пустым Deal - объект Deal создается на основании полей HistoryRecord
  // 2) при слиянии двух записей в одну (синхронизация по интервалам) - поле deal может перезаписываться
  Deal? deal;
  final DateTime startTime;
  final Duration duration;
  String? _phoneNumber; // обновляется только при синхронизации-слиянии
  String? _audioFileName; // обновляется только при синхронизации-слиянии
  String? _textTranscription; // обновляется только при синхронизации-слиянии
  String? _note;

  HistoryRecord({
    super.id,
    required this.deal,
    required this.startTime,
    required this.duration,
    final String? phoneNumber,
    final String? audioFileName,
    final String? textTranscription,
    final String? note,
    super.deleted,
    super.lastModified,
  }) : _phoneNumber = phoneNumber,
       _audioFileName = audioFileName,
       _textTranscription = textTranscription,
       _note = note {
    if (deal != null) {
      deal!.addRecord(this); // TODO: здесь неявное поведение, подумать как улучшить
    }
  }

  String? get phoneNumber => _phoneNumber;

  String? get audioFileName => _audioFileName;
  Future<String>? audioFilePath() async {
    final path = (await getApplicationDocumentsDirectory()).path;
    return '$path/$_audioFileName';
  }

  String? get textTranscription => _textTranscription;

  String? get note => _note;
  void updateNote(String note) => _update(() => _note = note);

  // Обновляем lastModified и у родителя
  @override
  void _update([VoidCallback? update]) {
    super._update(update);
    if (deal != null) deal!._update();
  }

  @override
  void mergeFrom(covariant HistoryRecord remote) {
    super.mergeFrom(remote);

    if (remote.phoneNumber != null) _phoneNumber = remote.phoneNumber;
    if (remote.audioFileName != null) _audioFileName = remote.audioFileName;
    if (remote.textTranscription != null) _textTranscription = remote.textTranscription;
    if (remote.note != null) _note = remote.note;
  }

  Future<void> saveToStorage() async {
    final history = di<HistoryVm>();

    if (deal == null) {
      _setNewDealFromThis();
      await history.addDeal(deal!);
    } else {
      await history.updateDeal(deal!);
    }
  }

  Deal _setNewDealFromThis() {
    if (deal != null) throw 'Field "deal" in instance of "HistoryRecord" is allready set';

    deal = Deal(
      id: id,
      created: startTime,
      lastModified: startTime,
      title: (textTranscription != null)
          ? (textTranscription!.length <= 150)
                ? textTranscription!
                : '${textTranscription!.substring(0, 150)}...'
          : (phoneNumber != null)
          ? phoneNumber!
          : startTime.toString(),
    )..addRecord(this);

    return deal!;
  }

  /// Вычисляет процент перекрытия интервалов, используется при merge звонка и аудиозаписи,
  /// которые создаются на разных устройствах, но на самом деле относятся к одному событию.
  bool isIntervalsOverlapped(HistoryRecord other) {
    // сливаем только параллельную запись со звонком, но не два звонка и не две записи
    if ((phoneNumber == null && other._audioFileName != null) || ((phoneNumber != null && other._audioFileName == null))) {
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
    print('calculateOverlapPercentage: $res %');
    return (res >= 70);
  }
}
