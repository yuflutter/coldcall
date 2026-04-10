import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/show_toastification.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/recorder/recognizer_service.dart';
import 'package:coldcall/features/recorder/_recorder_recognizer_vm.dart';
import 'package:coldcall/features/recorder/recorder_session.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Вью-модель для одновременной записи аудио и распознавания речи в текст.
/// Извлекает из DI конкретную реализацию рекогнайзера.
/// Сама инжектится в глобальный DI чтобы продолжать сессию записи/распознавания при навигации по экранам
class RecorderRecognizerVmImpl extends RecorderRecognizerVm {
  final _recognizer = di<RecognizerService>(); // ищем по имени суперкласса

  _Session? _session;
  @override
  bool get isSessionActive => (_session != null);

  @override
  bool get isPaused => _session?.isPaused ?? false;

  @override
  bool get isFlushing => _session?.isFlushing ?? false;

  @override
  String get textTranscription => _recognizer.textTranscription;

  @override
  void dispose() {
    _session?.dispose();
    _recognizer.dispose();
  }

  @override
  Future<void> init() async {
    try {
      await _recognizer.init();
      await Permission.microphone.request();
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  @override
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

  @override
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

  @override
  Future<void> resumeRecording() async {
    if (!isSessionActive) return;

    try {
      await _session?.recorder.resumeRecording();
      notify(() => _session!.isPaused = false);
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  @override
  Future<void> cancelRecording() async {
    _session?.dispose();
    notify(() => _session = null);
  }

  @override
  Future<void> stopRecording(BuildContext context) async {
    if (!isSessionActive) return;

    try {
      notify(() => _session!.isFlushing = true);

      final result = await _session!.recorder.stopRecording();
      await _recognizer.flushSession();
      notifyListeners();

      final record = HistoryRecord.manually(
        deal: _session!.deal,
        startTime: result.startTime,
        duration: result.duration,
        audioFileName: result.audioFilePath.split('/').last, // для синхронизации важно хранить только имя
        textTranscription: textTranscription.substring(0, min(textTranscription.length, 500)),
      );

      await di<HistoryVm>().updateDeal(record.deal!);

      if (_session?.deal != null) di<HistoryVm>().expandDealCard(_session!.deal!);

      // Сессия обнуляется, но еще не dispopsed, поэтому распознанный текст продолжает отображаться на экране
      if (context.mounted) showToastification(context, 'Запись сохранена в историю');

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
