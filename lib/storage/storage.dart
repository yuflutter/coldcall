import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:coldcall/entities/storage_bundle.dart';
import 'package:coldcall/entities/syncable.dart';
import 'package:coldcall/entities/sync_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO: Перенести хранение из файла в локальную СУБД, когда нибудь, может быть.
class Storage with SimpleChangeNotifier {
  static const _lastSyncStatusStorageKey = 'lastSyncStatus';
  static const _storageFileName = 'storage.json';

  var _deals = SyncableList<Deal>();
  List<Deal> get notDeletedDeals => List.from(_deals.notDeleted); // пришшлось итератор заменить на список для ScrollablePositionedList

  var _phoneBook = SyncableMap<PhoneNumber>();
  Iterable<PhoneNumber> get phoneBook => _phoneBook.notDeletedAndSorted;

  // Статус последней успешной синхронизации
  late SyncStatus _lastSyncStatus;
  SyncStatus get lastSyncStatus => _lastSyncStatus;

  late String _storageFilePath;
  late final _log = Log('$runtimeType');

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      try {
        _lastSyncStatus = SyncStatusMapper.fromJson(jsonDecode(prefs.getString(_lastSyncStatusStorageKey)!));
      } catch (e, s) {
        _log.err(e, s);
        _lastSyncStatus = SyncStatus();
      }
      notifyListeners();

      final dir = await getApplicationDocumentsDirectory();

      _storageFilePath = '${dir.path}/$_storageFileName';

      final file = File(_storageFilePath);
      if (file.existsSync()) {
        try {
          final bundle = StorageBundleMapper.fromJson(await file.readAsString());
          _deals = SyncableList(bundle.deals);
          _phoneBook = SyncableMap.fromList(bundle.phoneBook);
          for (final deal in _deals.notDeleted) {
            deal.normalizePhoneNumbers(_phoneBook);
          }
          notifyListeners();
        } catch (e, s) {
          _log.err(e, s);
          file.delete();
        }
      }
    } catch (e, s) {
      _log.err(e, s);
      rethrow;
    }
  }

  Future<void> saveAllToStorage() async {
    try {
      final bundle = StorageBundle(deals: _deals.all.toList(), phoneBook: _phoneBook.all.toList());
      final file = File(_storageFilePath);
      final json = bundle.toJson();
      Log.deb(json);
      await file.writeAsString(json);
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  /// Вызывается сервисом синхронизации после успешного завершения обмена.
  Future<void> updateLastSyncStatus(SyncStatus status) async {
    try {
      _lastSyncStatus = status;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncStatusStorageKey, jsonEncode(_lastSyncStatus));
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  // Future<void> addDeal(Deal deal, {bool raw = false}) async {
  //   _deals.add(deal);
  //   if (!raw) {
  //     notifyListeners();
  //     await saveToStorage();
  //   }
  // }

  // void insertDeal(Deal deal) => _deals.insert(deal);

  // У нас сущности мутабельные, а этот метод нужен только для переупорядочивания списка
  // (держим список всегда отсортированным по дате последнего изменения)
  Future<void> addOrUpdateAndSaveDeal(Deal deal, {bool raw = false}) async {
    deal.normalizePhoneNumbers(_phoneBook);
    _deals
      ..remove(deal)
      ..insert(deal);
    if (!raw) {
      notifyListeners();
      await saveAllToStorage();
    }
  }

  Future<void> deleteHistoryRecord(HistoryRecord record) async {
    if (record.audioFileName != null) {
      try {
        await File(await record.audioFilePath()!).delete();
      } catch (e) {
        _log.war('Error deleting file: $e');
      }
    }

    record.markDeleted();
    _deals
      ..remove(record.deal!)
      ..insert(record.deal!);
    notifyListeners();
    await saveAllToStorage();
  }

  Future<void> deleteDeal(Deal deal) async {
    // Не вижу смысла помечать на удаление все записи истории, если дело помечено.
    // for (final record in deal.records) {
    //   deleteHistoryRecord(record);
    // }
    deal.markDeleted();
    notifyListeners();
    await saveAllToStorage();
  }

  // Возвращает данные, измененные после даты последней синхронизации, хранящейся на другом устройстве
  StorageBundle getNotSyncedBundle(DateTime? lastSyncTime) => StorageBundle(
    deals: _deals.all.where((e) => lastSyncTime == null || e.lastModified.isAfter(lastSyncTime)).toList(),
    phoneBook: _phoneBook.all.where((e) => lastSyncTime == null || e.lastModified.isAfter(lastSyncTime)).toList(),
  );

  // Ищем дело с приблизительно совпадающими интервалами первой записи, и объединяем два в одно
  // Сами записи объединяем или нет - будет решено в Deal.mergeFrom()
  void mergeAndSaveDeal(Deal other) {
    other.normalizePhoneNumbers(_phoneBook);
    _deals.merge(
      other,
      (d1, d2) =>
          d1.notDeletedAndSortedRecords.isNotEmpty &&
          d2.notDeletedAndSortedRecords.isNotEmpty &&
          d1.notDeletedAndSortedRecords.first.isIntervalsOverlapped(d2.notDeletedAndSortedRecords.first),
    );
  }

  void mergeAndSavePhoneNumber(PhoneNumber otherPhone) {
    _phoneBook.merge(otherPhone);
  }
}
