import 'package:coldcall/core/dart_mappable_settings.dart';
import 'package:coldcall/core/log.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

part '_all_syncable_entities.mapper.dart';

// Внимание! после кодогена в файле маппера будет ошибка, заменить ошибочную строку на эту:
// get _records => (($value._records as SyncableList<HistoryRecord>).copyWith
//     .$chain((v) => call(records: v))) as SyncableListCopyWith<$R, SyncableList<HistoryRecord>, SyncableList<HistoryRecord>, HistoryRecord>;

// ---------------------------------------------------------------------------------------------

// Принял спорное архитектурное решение, что синхронизируемые объекты будут мутабельными.
// Не хотелось заморачиваться с заменой ссылок в полносвязном дереве. Хотя все равно пришлось при синхронизации.
// Зато теперь вся логика merge инкапсулирована внутри сущностей. Но и в случае copyWith() было бы так же.
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
  void markDeleted({bool raw = false}) {
    if (!raw) {
      _update(() => _deleted = true);
    } else {
      _deleted = true;
    }
  }

  DateTime get lastModified => _lastModified;

  bool isOlder(Syncable other) => lastModified.isBefore(other.lastModified);
  bool isNewer(Syncable other) => lastModified.isAfter(other.lastModified);

  /// использовать во всех потомках при ручном обновлении полей
  @mustCallSuper
  void _update(VoidCallback? updater, {bool raw = false}) {
    updater?.call();
    if (!raw) _lastModified = DateTime.now();
  }

  /// Используется стратегия Last Write Wins для всех полей
  @mustBeOverridden
  @mustCallSuper
  void mergeFrom(Syncable other) {
    _deleted = other.deleted;
  }
}

// ---------------------------------------------------------------------------------------------

// Класс сделан с единственной целью - чтобы не дублировать алгоритмы insert и merge
@MappableClass()
class SyncableList<T extends Syncable> with SyncableListMappable {
  final List<T> _items;

  SyncableList([final List<T>? items]) : _items = items ?? [];

  Iterable<T> get items => _items.where((e) => !e.deleted); // возвращаем итератор, что не так надежно, но производительно

  void add(T item) => _items.add(item);
  void remove(T item) => _items.remove(item);

  Future<void> insert(T item) async {
    for (var i = _items.length - 1; i >= 0; i--) {
      final it = _items[i];
      if (it.isOlder(item)) {
        _items.insert(i + 1, item);
        return;
      }
    }
    _items.insert(0, item);
  }

  void merge(T other, bool Function(T item1, T intem2) softMergeCondition) {
    // ищем запись по ID
    var it = _items.firstWhereOrNull((e) => e.id == other.id);

    if (it == null) {
      // Ищем похожую запись по мягкому условию, после чего объединяем две в одну
      it = _items.firstWhereOrNull((e) => softMergeCondition(e, other));

      // добавляем новую запись
      if (it == null) {
        _items.add(other);
        return;
      }
    }

    // обновляем поля
    if (it != null) {
      if (it.isNewer(other)) {
        it.mergeFrom(other);
      } else {
        other.mergeFrom(it);
        insert(other);
        it.markDeleted(raw: true);
      }
    }
  }
}

// ---------------------------------------------------------------------------------------------

@MappableClass()
class Deal extends Syncable with DealMappable {
  String _title;
  final SyncableList<HistoryRecord> _records;

  Deal({
    super.id,
    super.created,
    required final String title,
    final SyncableList<HistoryRecord>? records,
    super.deleted,
    super.lastModified,
  }) : _title = title,
       _records = records ?? SyncableList<HistoryRecord>() {
    for (var r in _records.items) {
      r.deal = this; // восстанавливаем ссылку, обрубленную сериализатором TODO: здесь неявное поведение, подумать как улучшить
    }
  }

  String get title => _title;
  void updateTitle(String title) => _update(() => _title = title);

  Iterable<HistoryRecord> get records => _records.items; // возвращаем итератор, что не так надежно, но производительно

  void addRecord(HistoryRecord record, {bool raw = false}) {
    record.deal = this;
    _update(() => _records.add(record), raw: raw);
  }

  void insertRecord(HistoryRecord record) {
    record.deal = this;
    _records.insert(record);
  }

  bool get hasCalls => records.any((r) => r.phoneNumber != null);
  bool get hasAudios => records.any((r) => r.audioFileName != null);
  String? get lastPhoneNumber => records.firstWhereOrNull((r) => r.phoneNumber != null)?.phoneNumber;

  @override
  void mergeFrom(covariant Deal other) {
    super.mergeFrom(other);

    _title = other.title;

    for (final otherRecord in other.records) {
      _records.merge(
        otherRecord,
        (r1, r2) =>
            r1.isIntervalsOverlapped(r2) &&
            ((r1.phoneNumber == null && r2.phoneNumber != null) || (r1.audioFileName == null && r2.audioFileName != null)),
      );
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
  // 1) при создании HistoryRecord с пустым Deal - объект Deal создается позже на основании полей HistoryRecord
  // 2) при слиянии двух дел в одно (синхронизация по интервалам) - поле deal у записи может перезаписываться
  Deal? deal;
  final DateTime startTime;
  final Duration duration;
  String? _phoneNumber; // обновляется только при синхронизации-слиянии
  String? _audioFileName; // обновляется только при синхронизации-слиянии
  String? _textTranscription; // обновляется только при синхронизации-слиянии
  String? _note;

  @MappableConstructor()
  HistoryRecord({
    required super.id,
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
       _note = note;

  factory HistoryRecord.manually({
    final Deal? deal,
    required final DateTime startTime,
    required final Duration duration,
    final String? phoneNumber,
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
      audioFileName: audioFileName,
      textTranscription: textTranscription,
      note: note,
    );
    record.deal ??= record._newDealFromThis();
    record.deal!.addRecord(record); // здесь происходит обновление _lastModified у Deal
    return record;
  }

  Deal _newDealFromThis() => Deal(
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
  );

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
  void _update(VoidCallback? updater, {bool raw = false}) {
    super._update(updater, raw: raw);
    if (deal != null && !raw) deal!._update(null);
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
    Log('$runtimeType').inf('calculateOverlapPercentage: $res %');

    return (res >= 70);
  }
}
