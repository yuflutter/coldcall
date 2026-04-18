import 'package:coldcall/entities/syncable.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'deal.mapper.dart';

// TODO: Внимание!!! после кодогена в файле маппера будет ошибка, заменить ошибочную строку на эту:

// get _records => (($value._records as SyncableList<HistoryRecord>).copyWith
//     .$chain((v) => call(records: v))) as SyncableListCopyWith<$R, SyncableList<HistoryRecord>, SyncableList<HistoryRecord>, HistoryRecord>;

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
    // Восстанавливаем ссылку, обрубленную сериализатором TODO: здесь неявное поведение, подумать как улучшить
    for (var r in _records.notDeleted) {
      r.deal = this;
    }
  }

  // Нормализуем ссылки на номера телефонов при десериализации или ручном создании записи
  void normalizePhoneNumbers(SyncableMap<PhoneNumber> phoneBook) {
    for (final record in _records.notDeleted) {
      record.normalizePhoneNumber(phoneBook);
    }
  }

  String get title => _title;
  void updateTitle(String title) => update(() => _title = title);

  // для отображения в интерфейсе
  Iterable<HistoryRecord> get records => _records.notDeleted.sortedBy((r) => r.startTime);

  void addRecord(HistoryRecord record, {bool raw = false}) {
    record.deal = this;
    update(() => _records.insert(record), raw: raw);
  }

  // void insertRecord(HistoryRecord record) {
  //   record.deal = this;
  //   _records.insert(record);
  // }

  bool get hasCalls => records.any((r) => r.phoneNumber != null);
  bool get hasAudios => records.any((r) => r.audioFileName != null);
  PhoneNumber? get lastPhoneNumber => records.firstWhereOrNull((r) => r.phoneNumber != null)?.phoneNumber;

  @override
  void mergeFrom(covariant Deal other) {
    super.mergeFrom(other);

    _title = other.title;

    for (final otherRecord in other.records) {
      otherRecord.deal = this;
      _records.merge(otherRecord, (r1, r2) => r1.isIntervalsOverlapped(r2));
    }
  }
}
