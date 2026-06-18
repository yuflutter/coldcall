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
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO: Перенести хранение из файла в локальную СУБД, когда нибудь, может быть.
class Storage with SimpleChangeNotifier {
  static const _lastSyncStatusStorageKey = 'lastSyncStatus';
  static const _storageFileName = 'storage.json';

  var _deals = SyncableList<Deal>();
  List<Deal> get notDeletedAndSortedDeals => _deals.notDeleted.sorted((e1, e2) => (e1.lastModified.isBefore(e2.lastModified)) ? 1 : -1);

  var _phoneBook = SyncableMap<PhoneNumber>();
  List<PhoneNumber> get phoneBook => _phoneBook.notDeleted.sorted((e1, e2) => (e1.lastModified.isBefore(e2.lastModified)) ? 1 : -1);

  // Статус последней успешной синхронизации
  late SyncStatus _lastSyncStatus;
  SyncStatus get lastSyncStatus => _lastSyncStatus;

  Future<String> storageDir() async => (await getApplicationDocumentsDirectory()).path + '/coldcall';

  late String _storageFilePath;
  late final _log = Log('$runtimeType');

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      try {
        _lastSyncStatus = SyncStatusMapper.fromJson(jsonDecode(prefs.getString(_lastSyncStatusStorageKey)!));
      } catch (e, s) {
        _log.war(e, stack: s);
        _lastSyncStatus = SyncStatus();
      }

      final dir = await storageDir();
      _storageFilePath = '$dir/$_storageFileName';
      final file = File(_storageFilePath);
      if (file.existsSync()) {
        try {
          final bundle = StorageBundleMapper.fromJson(await file.readAsString());
          _phoneBook = SyncableMap.fromList(bundle.phoneBook);
          _deals = SyncableList(bundle.deals);
          for (final deal in _deals.notDeleted) {
            deal.normalizePhoneNumbers(_phoneBook);
          }
        } catch (_) {
          file.deleteSync();
          rethrow;
        }
      }
    } catch (e, s) {
      _log.err(e, s);
      notifyListeners();
      rethrow;
    }
    notifyListeners();
    Log.deb('Storage.init() has done');
  }

  Future<void> saveAllToStorage() async {
    try {
      final bundle = StorageBundle(deals: _deals.all.toList(), phoneBook: _phoneBook.all.toList());
      final file = File(_storageFilePath);
      final json = bundle.toJson();
      // Log.deb(json);
      await file.writeAsString(json);
      Log.deb('Deal list saved in storage');
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  /// Вызывается сервисом синхронизации после успешного завершения обмена.
  Future<void> updateLastSyncStatus(SyncStatus status) async {
    notify(() => _lastSyncStatus = status);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncStatusStorageKey, jsonEncode(_lastSyncStatus));
  }

  // У нас все объекты мутабельные, поэтому здесь только вставка в список и сохранение в storage
  Future<void> addOrUpdateAndSaveDeal(Deal deal) async {
    deal.normalizePhoneNumbers(_phoneBook);
    _deals.merge(deal);
    notifyListeners();
    await saveAllToStorage();
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
    await addOrUpdateAndSaveDeal(record.deal!);
  }

  Future<void> deleteDeal(Deal deal) async {
    // Не вижу смысла помечать на удаление все записи истории, если дело помечено.
    // for (final record in deal.records) {
    //   deleteHistoryRecord(record);
    // }
    deal.markDeleted();
    await addOrUpdateAndSaveDeal(deal);
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
      softMergeCondition: (d1, d2) =>
          d1.notDeletedAndSortedRecords.isNotEmpty &&
          d2.notDeletedAndSortedRecords.isNotEmpty &&
          d1.notDeletedAndSortedRecords.first.isIntervalsOverlapped(d2.notDeletedAndSortedRecords.first),
    );
  }

  void mergeAndSavePhoneNumber(PhoneNumber otherPhone) {
    _phoneBook.merge(otherPhone);
  }

  /// Сжатие базы данных:
  /// - удаляет записи с флагом deleted из _deals и _phoneBook
  /// - удаляет аудиофайлы, на которые нет актуальных (неудалённых) ссылок
  /// Возвращает статистику: количество удалённых записей и файлов.
  Future<StorageCompressResult> compress() async {
    int dealsRemoved = 0;
    int phoneBookRemoved = 0;
    int audioFilesRemoved = 0;

    // 1. Собираем имена аудиофайлов, на которые есть актуальные (неудалённые) ссылки
    final referencedAudioFiles = <String>{};
    for (final deal in _deals.notDeleted) {
      for (final record in deal.notDeletedAndSortedRecords) {
        if (record.audioFileName != null) {
          referencedAudioFiles.add(record.audioFileName!);
        }
      }
    }

    // 2. Удаляем аудиофайлы без актуальных ссылок
    final dir = await storageDir();
    final directory = Directory(dir);
    if (directory.existsSync()) {
      final audioExtensions = {'.m4a', '.mp3', '.wav', '.aac', '.ogg', '.amr'};
      for (final entity in directory.listSync()) {
        if (entity is File) {
          final ext = entity.path.substring(entity.path.lastIndexOf('.')).toLowerCase();
          if (audioExtensions.contains(ext)) {
            final fileName = entity.path.split('/').last;
            if (!referencedAudioFiles.contains(fileName)) {
              try {
                await entity.delete();
                audioFilesRemoved++;
                _log.inf('compress: deleted orphaned audio file "$fileName"');
              } catch (e) {
                _log.war('compress: failed to delete audio file "$fileName": $e');
              }
            }
          }
        }
      }
    }

    // 3. Убираем помеченные на удаление записи из _deals
    final newDeals = SyncableList<Deal>(_deals.notDeleted.toList());
    dealsRemoved = _deals.all.where((d) => d.deleted).length;
    _deals = newDeals;

    // 4. Убираем помеченные на удаление записи из _phoneBook
    final activePhoneNumbers = _phoneBook.notDeleted.toList();
    phoneBookRemoved = _phoneBook.all.where((p) => p.deleted).length;
    _phoneBook = SyncableMap.fromList(activePhoneNumbers);

    // 5. Сохраняем результат
    await saveAllToStorage();
    notifyListeners();

    _log.inf('compress: removed $dealsRemoved deals, $phoneBookRemoved phone book entries, $audioFilesRemoved audio files');
    return StorageCompressResult(dealsRemoved: dealsRemoved, phoneBookRemoved: phoneBookRemoved, audioFilesRemoved: audioFilesRemoved);
  }
}

class StorageCompressResult {
  final int dealsRemoved;
  final int phoneBookRemoved;
  final int audioFilesRemoved;

  const StorageCompressResult({required this.dealsRemoved, required this.phoneBookRemoved, required this.audioFilesRemoved});

  bool get hasChanges => dealsRemoved > 0 || phoneBookRemoved > 0 || audioFilesRemoved > 0;
}
