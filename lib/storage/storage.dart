import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:coldcall/entities/syncable.dart';
import 'package:coldcall/entities/sync_status.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO: Перенести хранение из файла в локальную СУБД, когда нибудь, может быть.
class Storage with SimpleChangeNotifier {
  var _deals = SyncableList<Deal>();
  // для интерфейса
  Iterable<Deal> get deals => _deals.items;
  // для синхронизатора
  Iterable<Deal> notSyncedDeals(DateTime? lastSyncTime) =>
      _deals.items.where((e) => lastSyncTime == null || e.lastModified.isAfter(lastSyncTime));

  var _phoneBook = SyncableMap<PhoneNumber>();
  // для интерфейса
  Iterable<PhoneNumber> get phoneBook => _phoneBook.items;
  // для синхронизатора
  Iterable<PhoneNumber> notSyncedPhoneBook(DateTime? lastSyncTime) =>
      _phoneBook.items.where((e) => lastSyncTime == null || e.lastModified.isAfter(lastSyncTime));

  // Статус последней успешной синхронизации
  late SyncStatus _lastSyncStatus;
  SyncStatus get lastSyncStatus => _lastSyncStatus;
  static const _lastSyncStatusStorageKey = 'lastSyncStatus';

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
      _storageFilePath = '${dir.path}/history_deals.json';

      final file = File(_storageFilePath);
      if (file.existsSync()) {
        try {
          final json = await file.readAsString();
          _deals = SyncableList((jsonDecode(json) as List).map((e) => DealMapper.fromJson(e)).toList());
          for (final deal in _deals.items) {
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

  Future<void> saveAllToStorage() async {
    try {
      final json = jsonEncode(deals.map((e) => e.toJson()).toList());
      final file = File(_storageFilePath);
      await file.writeAsString(json);
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

  // Ищем дело с приблизительно совпадающими интервалами первой записи, и объединяем два в одно
  // Сами записи объединяем или нет - будет решено в Deal.mergeFrom()
  void mergeAndSaveDeal(Deal other) {
    other.normalizePhoneNumbers(_phoneBook);
    _deals.merge(
      other,
      (d1, d2) => d1.records.isNotEmpty && d2.records.isNotEmpty && d1.records.first.isIntervalsOverlapped(d2.records.first),
    );
  }

  Future<void> deleteHistoryRecord(HistoryRecord record) async {
    // Файлы пока не удаляем, может сделать режим восстановления из корзины?
    // if (record.audioFilePath != null) {
    //   try {
    //     final file = File(record.audioFilePath!);
    //     if (await file.exists()) {
    //       await file.delete();
    //     }
    //   } catch (e) {
    //     print('Error deleting audio file: $e');
    //   }
    // }
    // records.remove(record);

    record.markDeleted();
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
}
