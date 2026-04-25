import 'dart:async';
import 'dart:typed_data';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/show_toastification.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/recorder/recognizer_service.dart';
import 'package:coldcall/features/recorder/recorder_session.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Вью-модель для одновременной записи аудио и распознавания речи в текст.
/// Извлекает из DI конкретную реализацию рекогнайзера.
/// Сама инжектится в глобальный DI чтобы продолжать сессию записи/распознавания при навигации по экранам
class RecorderRecognizerVm with SimpleChangeNotifier {
  final _recognizer = di<RecognizerService>(); // ищем по имени суперкласса

  _Session? _session;
  bool get isSessionActive => (_session != null);

  bool get isPaused => _session?.isPaused ?? false;

  bool get isFlushing => _session?.isFlushing ?? false;

  String get textTranscription => _recognizer.textTranscription;

  @override
  void dispose() {
    _session?.dispose();
    _recognizer.dispose();
  }

  Future<void> init() async {
    try {
      await _recognizer.init();
      await Permission.microphone.request();
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> startRecording({Deal? deal}) async {
    try {
      _session?.dispose();

      notify(() => _session = _Session(deal: deal, recognizer: _recognizer, recognizerListener: notifyListeners));

      final audioStream = await _session!.recorder.startRecording();

      _session!.audioStreamSubs = audioStream
          .asyncMap((audioChunk) async {
            //TODO: добавить логгирование ошибки здесь, ведь прокидывать наверх в презентер нельзя
            await _recognizer.acceptWaveform(audioChunk);
            return audioChunk;
          })
          .listen((_) {
            notifyListeners();
          });
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> pauseRecording() async {
    if (!isSessionActive) return;

    try {
      notify(() => _session!.isFlushing = true);

      await _session?.recorder.pauseRecording();
      await _recognizer.flushSession();

      notify(() {
        _session!.isFlushing = false;
        _session!.isPaused = true;
      });
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> resumeRecording() async {
    if (!isSessionActive) return;

    try {
      await _session?.recorder.resumeRecording();
      notify(() => _session!.isPaused = false);
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  void cancelRecording() async {
    _session?.dispose();
    _recognizer.disposeSession();
    notify(() => _session = null);
  }

  Future<void> stopRecording(BuildContext context) async {
    if (!isSessionActive) return;

    try {
      notify(() => _session!.isFlushing = true);

      final result = await _session!.recorder.stopRecording();
      await _recognizer.flushSession();
      notifyListeners();

      final record = HistoryRecord.manually(
        deal: _session!.deal, // если тут null - дело создается автоматически внутри конструктора
        startTime: result.startTime,
        duration: result.duration,
        audioFileName: result.audioFilePath.split('/').last, // для синхронизации важно хранить только имя
        textTranscription: textTranscription,
      );

      if (_session!.deal != null) {
        _session!.deal!.addRecord(record);
      }

      await di<Storage>().addOrUpdateAndSaveDeal(record.deal!);

      if (_session?.deal != null) di<HistoryVm>().expandCollapseDealCard(_session!.deal!, forceSet: true);

      if (context.mounted) showToastification(context, 'Запись сохранена в историю');

      // Сессия обнуляется, но  _recognizer.disposeSession() не вызван, поэтому распознанный текст продолжает отображаться на экране
      notify(() => _session = null);
    } catch (e, s) {
      Err.add(e, s);
    }
  }
}

/// Сессия содержит все переменные, необходимые для конкретного сеанса (исключая тяжелую нейросеть)
/// При старте нового сеанса сессия просто заменяется на новую.
/// Это предотвращает проблему управления связанным набором переменных, и корректной их очистки в конце каждого сеанса.
class _Session {
  final Deal? deal;
  final RecognizerService recognizer;
  final VoidCallback recognizerListener;

  late final recorder = RecorderSession();
  StreamSubscription<Uint8List>? audioStreamSubs;

  var isPaused = false;
  var isFlushing = false;

  _Session({required this.deal, required this.recognizer, required this.recognizerListener}) {
    recognizer
      ..startSession()
      ..addListener(recognizerListener);
  }

  void dispose() {
    recognizer
      ..removeListener(recognizerListener)
      ..disposeSession();
    audioStreamSubs?.cancel();
    recorder.dispose();
  }
}
