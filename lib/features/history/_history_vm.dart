import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/core/show_toastification.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/_all_syncable_entities.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:coldcall/entities/sync_status.dart';
import 'package:coldcall/features/dialer/dialer_vm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TODO: Перенести хранение из файла в локальную СУБД, когда нибудь.
class HistoryVm with SimpleChangeNotifier {
  var _deals = SyncableList<Deal>();
  // для интерфейса
  Iterable<Deal> get deals => _deals.items;
  // для синхронизатора
  Iterable<Deal> notSyncedDeals(DateTime? lastSyncTime) =>
      _deals.items.where((e) => lastSyncTime == null || e.lastModified.isAfter(lastSyncTime));

  // Статус последней успешной синхронизации
  late SyncStatus _lastSyncStatus;
  SyncStatus get lastSyncStatus => _lastSyncStatus;
  static const _lastSyncStatusStorageKey = 'lastSyncStatus';

  /// Вызывается сервисом синхронизации после успешного завершения обмена.
  Future<void> updateLastSyncStatus(SyncStatus status) async {
    _lastSyncStatus = status;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncStatusStorageKey, jsonEncode(_lastSyncStatus));
  }

  // раскрытие карточки Deal
  Deal? _currentExpandedDeal;
  int? get currentExpandedDealId => _currentExpandedDeal?.id;
  void expandDealCard(Deal deal) {
    notify(() => _currentExpandedDeal = deal);
  }

  // аудиоплеер
  _AudioSession? _audioSession;
  int? get currentPlayingRecordId => _audioSession?.currentPlayingRecord.id;
  bool get isAudioPaused => _audioSession?.isPaused ?? false;
  Duration get currentPlayingPosition => _audioSession?.position ?? Duration.zero;
  Duration get currentPlayingDuration => _audioSession?.duration ?? Duration.zero;

  // диалер
  DialerVm? dialerOverlayModel;
  bool get isDialerShown => (dialerOverlayModel != null);

  late String _storageFilePath;
  late final _log = Log('$runtimeType');

  Future<void> initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      try {
        notify(() => _lastSyncStatus = SyncStatusMapper.fromJson(prefs.getString(_lastSyncStatusStorageKey)!));
      } catch (e, s) {
        _log.err(e, s);
        _lastSyncStatus = SyncStatus();
      }

      final dir = await getApplicationDocumentsDirectory();
      _storageFilePath = '${dir.path}/history_deals.json';

      final file = File(_storageFilePath);
      if (file.existsSync()) {
        final json = await file.readAsString();
        try {
          notify(() {
            _deals = SyncableList((jsonDecode(json) as List).map((e) => DealMapper.fromJson(e)).toList());
            _currentExpandedDeal = null;
          });
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

  Future<void> saveToStorage() async {
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
  Future<void> updateDeal(Deal deal, {bool raw = false}) async {
    _deals
      ..remove(deal)
      ..insert(deal);
    if (!raw) {
      notifyListeners();
      await saveToStorage();
    }
  }

  // Ищем дело с приблизительно совпадающими интервалами первой записи, и объединяем два в одно
  // Сами записи объединяем или нет - будет решено в Deal.mergeFrom()
  void mergeDeal(Deal other) => _deals.merge(
    other,
    (d1, d2) => d1.records.isNotEmpty && d2.records.isNotEmpty && d1.records.first.isIntervalsOverlapped(d2.records.first),
  );

  Future<void> deleteHistoryRecord(HistoryRecord record) async {
    if (record.id == currentPlayingRecordId) await stopAndDisposeAudio();

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
    await saveToStorage();
  }

  Future<void> deleteDeal(Deal deal) async {
    // Не вижу смысла помечать на удаление все записи истории, если дело помечено.
    // for (final record in deal.records) {
    //   deleteHistoryRecord(record);
    // }
    deal.markDeleted();
    notifyListeners();
    await saveToStorage();
  }

  void expandCollapseDeal(Deal deal) {
    notify(() => _currentExpandedDeal = (_currentExpandedDeal != deal) ? deal : null);
  }

  void expandDeal(Deal deal) {
    notify(() => _currentExpandedDeal = deal);
  }

  Future<void> startStopAudio(BuildContext context, HistoryRecord record) async {
    try {
      if (currentPlayingRecordId == record.id) {
        await stopAndDisposeAudio();
      } else {
        await stopAndDisposeAudio();
        _audioSession = _AudioSession(parent: this, currentPlayingRecord: record, onPlayComplete: stopAndDisposeAudio);
        notifyListeners();
        await _audioSession!.startAudio();
      }
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> pauseResumeAudio() async {
    await _audioSession?.pauseResumeAudio();
  }

  Future<void> seekAudioTo(Duration position) async {
    await _audioSession?.seekTo(position);
  }

  Future<void> stopAndDisposeAudio() async {
    await _audioSession?.stopAudio();
    await _audioSession?.dispose();
    notify(() => _audioSession = null);
  }

  // Future<void> improveTranscription(HistoryRecord record) async {
  //   if (record.audioFilePath == null) return;

  //   try {
  //     final recognizer = NativeOfflineRecognizer();
  //     final res = await recognizer.transcribeAudio(record.audioFilePath!);
  //     print('IMPROVE $res');
  //     if (res != null) record.updateTextTranscription(res);
  //   } catch (e, s) {
  //     Err.add(e, s);
  //   }
  // }

  Future<void> downloadAudio(HistoryRecord record) async {
    final file = File(await record.audioFilePath()!);
    final bytes = await file.readAsBytes();
    final fileName =
        record.startTime.toIso8601String().substring(0, 16).replaceFirst('T', ' ') + '.' + record.audioFileName!.split('.').last;
    await FilePicker.platform.saveFile(dialogTitle: 'Сохранить аудиозапись', fileName: fileName, bytes: bytes);
  }

  void showDialer(BuildContext context, {required Deal deal, String? phoneNumber}) {
    notify(
      () => dialerOverlayModel = DialerVm(
        initialPhone: phoneNumber,
        deal: deal,
        closeFromOutside: (isCallEnded) => _closeDialer(context, isCallEnded, deal),
      ),
    );
  }

  void _closeDialer(BuildContext context, bool isCallEnded, Deal deal) async {
    notify(() => dialerOverlayModel = null);
    if (isCallEnded) {
      expandDealCard(deal);
      if (context.mounted) showToastification(context, 'Звонок сохранен в историю');
    }
  }
}

/// Сессия содержит все переменные, необходимые для сеанса воспроизведения аудиозаписи
/// При старте нового сеанса старая сессия уничтожается, и заменяется на новую.
/// Это предотвращает проблему управления связанным набором переменных, и корректной их очистки в конце каждого сеанса.
class _AudioSession {
  final SimpleChangeNotifier parent;
  final HistoryRecord currentPlayingRecord;
  final VoidCallback onPlayComplete;

  final _player = AudioPlayer();
  late final StreamSubscription _positionSubs;
  late final StreamSubscription _durationSubs;
  late final StreamSubscription _stateSubs;

  var isPaused = false;
  var position = Duration.zero;
  var duration = Duration.zero;

  _AudioSession({required this.parent, required this.currentPlayingRecord, required this.onPlayComplete}) {
    _positionSubs = _player.onPositionChanged.listen((p) => parent.notify(() => position = p));

    _durationSubs = _player.onDurationChanged.listen((d) => parent.notify(() => duration = d));

    _stateSubs = _player.onPlayerStateChanged.listen(
      (state) => switch (state) {
        .paused => parent.notify(() => isPaused = true),
        .playing => parent.notify(() => isPaused = false),
        .completed => onPlayComplete(),
        _ => null,
      },
    );
  }

  Future<void> dispose() async {
    _positionSubs.cancel();
    _durationSubs.cancel();
    _stateSubs.cancel();
    await _player.dispose();
  }

  Future<void> startAudio() async {
    if (currentPlayingRecord.audioFileName != null) {
      await _player.play(DeviceFileSource(await currentPlayingRecord.audioFilePath()!));
    }
  }

  Future<void> pauseResumeAudio() async {
    if (isPaused) {
      await _player.resume();
    } else {
      await _player.pause();
    }
  }

  Future<void> stopAudio() {
    return _player.stop();
  }

  Future<void> seekTo(Duration position) {
    return _player.seek(position);
  }
}
