import 'dart:async';
import 'dart:isolate';
import 'package:coldcall/features/recorder/recognizer_service.dart';
import 'package:coldcall/features/recorder/sherpa_utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:flutter/services.dart';

/// Команды для общения с изолятом
enum _IsolateCommand { init, start, audioChunk, flush, stop }

/// Попытка перевести инференс модели в изолят. Ускорения не заметил. Но хоть интерфейс не фризит.
class RecognizerServiceSherpaIsolate extends RecognizerService {
  Isolate? _isolate;

  SendPort? _toIsolatePort;
  final _fromIsolatePort = ReceivePort();

  final _fromIsolateFlushPort = ReceivePort(); // ожидаем окончания flushSession)
  Completer<void>? _flushCompleter;

  final _transcription = StringBuffer();
  bool _active = false;

  @override
  bool get isSessionActive => _active;

  @override
  String get textTranscription => _transcription.toString();

  @override
  Future<void> init() async {
    if (_isolate != null) return;

    final modelPath = await SherpaUtils.copyAssetsToDocuments(['model.int8.onnx', 'tokens.txt', 'silero_vad.onnx']);

    // Запускаем изолят
    _isolate = await Isolate.spawn(_recognizerWorker, {
      'port': _fromIsolatePort.sendPort,
      'flushPort': _fromIsolateFlushPort.sendPort,
      'modelPath': modelPath,
    });

    // Слушаем ответы из изолята
    _fromIsolatePort.listen((message) {
      if (message is SendPort) {
        _toIsolatePort = message;
      } else if (message is String) {
        // Получили новый кусок текста
        notify(() => _transcription.write('$message '));
      }
    });

    // Слушаем подтверждение flush()
    _fromIsolateFlushPort.listen((_) {
      _flushCompleter?.complete();
    });

    // Ждем, пока прокинется SendPort
    while (_toIsolatePort == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _toIsolatePort!.send({'cmd': _IsolateCommand.init});
  }

  @override
  void startSession() {
    _transcription.clear();
    _active = true;
    _toIsolatePort?.send({'cmd': _IsolateCommand.start});
    notify(() {});
  }

  @override
  FutureOr<void> acceptWaveform(Uint8List audioChunk) {
    // Передаем байты в изолят. Isolate.spawn в современных версиях Dart
    // эффективно передает Uint8List без полного копирования.
    _toIsolatePort?.send({'cmd': _IsolateCommand.audioChunk, 'data': audioChunk});
  }

  @override
  FutureOr<void> flushSession() async {
    _flushCompleter = Completer<void>();
    _toIsolatePort?.send({'cmd': _IsolateCommand.flush});
    await _flushCompleter!.future;
  }

  @override
  void disposeSession() async {
    _active = false;
    _toIsolatePort?.send({'cmd': _IsolateCommand.stop});
    _transcription.clear();
    notify(() {});
  }

  @override
  void dispose() {
    _isolate?.kill();
    _fromIsolatePort.close();
    super.dispose();
  }
}

/// Точка входа в изолят. Вся тяжелая логика тут.
void _recognizerWorker(Map<String, dynamic> initData) async {
  final SendPort fromIsolatePort = initData['port'];
  final SendPort fromIsolateFlushPort = initData['flushPort'];
  final String modelPath = initData['modelPath'];

  VoiceActivityDetector? vad;
  OfflineRecognizer? recognizer;

  final toIsolatePort = ReceivePort();
  fromIsolatePort.send(toIsolatePort.sendPort);

  await for (final message in toIsolatePort) {
    final cmd = message['cmd'] as _IsolateCommand;

    switch (cmd) {
      case _IsolateCommand.init:
        initBindings();

        vad = VoiceActivityDetector(
          config: VadModelConfig(
            sileroVad: SileroVadModelConfig(
              model: '$modelPath/silero_vad.onnx',
              threshold: 0.4, // было 0.5
              minSilenceDuration: 0.4, // было 0.5
              minSpeechDuration: 0.25,
              windowSize: 512,
            ),
            sampleRate: 16000,
            numThreads: 1,
          ),
          bufferSizeInSeconds: 30,
        );

        recognizer = OfflineRecognizer(
          OfflineRecognizerConfig(
            model: OfflineModelConfig(
              nemoCtc: OfflineNemoEncDecCtcModelConfig(model: '$modelPath/model.int8.onnx'),
              tokens: '$modelPath/tokens.txt',
              numThreads: 4, // в изоляте можем себе позволить
            ),
            decodingMethod: 'greedy_search',
          ),
        );
        break;

      case _IsolateCommand.start:

        // Можно сбросить внутренние буферы VAD, если нужно
        break;

      case _IsolateCommand.audioChunk:
        final data = message['data'] as Uint8List;
        final samples = SherpaUtils.pcm16ToFloat32(data);
        vad?.acceptWaveform(samples);
        _processVad(vad, recognizer, fromIsolatePort);
        break;

      case _IsolateCommand.flush:
        vad?.flush();
        _processVad(vad, recognizer, fromIsolatePort);
        fromIsolateFlushPort.send(true);
        break;

      case _IsolateCommand.stop:

        // Логика остановки
        break;
    }
  }
}

/// Вспомогательная функция внутри изолята для обработки сегментов
void _processVad(VoiceActivityDetector? vad, OfflineRecognizer? recognizer, SendPort fromIsolatePort) {
  if (vad == null || recognizer == null) return;

  while (!vad.isEmpty()) {
    final segment = vad.front();
    vad.pop();

    final stream = recognizer.createStream();
    stream.acceptWaveform(samples: segment.samples, sampleRate: 16000);
    recognizer.decode(stream);
    final text = recognizer.getResult(stream).text.trim();
    stream.free();

    if (text.isNotEmpty) {
      fromIsolatePort.send(text); // Отправляем текст в главный поток
    }
  }
}
