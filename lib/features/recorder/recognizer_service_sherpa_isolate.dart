import 'dart:async';
import 'dart:isolate';
import 'package:coldcall/features/recorder/recognizer_service_sherpa.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:flutter/services.dart';

/// Команды для общения с изолятом
enum _IsolateCommand { init, start, accept, flush, stop }

/// Неудачная попытка перевести инференс модели в изолят. Работает еще медленнее, чем синхронная версия.
class RecognizerServiceSherpaIsolate extends RecognizerServiceSherpa {
  Isolate? _isolate;

  SendPort? _toIsolate;
  final _fromIsolate = ReceivePort();

  final _fromIsolateFlush = ReceivePort(); // ожидаем окончания flushSession)
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

    // ВАЖНО: copyAssetsToDocuments должен быть доступен или путь передан извне
    // Для примера считаем, что пути те же
    final modelPath = await copyAssetsToDocuments();

    // Запускаем изолят
    _isolate = await Isolate.spawn(_recognizerWorker, {
      'port': _fromIsolate.sendPort,
      'flushPort': _fromIsolateFlush.sendPort,
      'modelPath': modelPath,
    });

    // Слушаем ответы из изолята
    _fromIsolate.listen((message) {
      if (message is SendPort) {
        _toIsolate = message;
      } else if (message is String) {
        // Получили новый кусок текста
        notify(() => _transcription.write('$message '));
      }
    });

    // Слушаем подтверждение flush()
    _fromIsolateFlush.listen((_) {
      _flushCompleter?.complete();
    });

    // Ждем, пока прокинется SendPort
    while (_toIsolate == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _toIsolate!.send({'cmd': _IsolateCommand.init});
  }

  @override
  void startSession() {
    _transcription.clear();
    _active = true;
    _toIsolate?.send({'cmd': _IsolateCommand.start});
    notify(() {});
  }

  @override
  FutureOr<void> acceptWaveform(Uint8List audioChunk) {
    // Передаем байты в изолят. Isolate.spawn в современных версиях Dart
    // эффективно передает Uint8List без полного копирования.
    _toIsolate?.send({'cmd': _IsolateCommand.accept, 'data': audioChunk});
  }

  @override
  FutureOr<void> flushSession() async {
    _flushCompleter = Completer<void>();
    _toIsolate?.send({'cmd': _IsolateCommand.flush});
    await _flushCompleter!.future;
  }

  @override
  Future<void> disposeSession() async {
    _active = false;
    _toIsolate?.send({'cmd': _IsolateCommand.stop});
    notify(() {});
  }

  @override
  void dispose() {
    _isolate?.kill();
    _fromIsolate.close();
    super.dispose();
  }
}

/// Точка входа в изолят. Вся тяжелая логика тут.
void _recognizerWorker(Map<String, dynamic> initData) async {
  final SendPort mainSendPort = initData['port'];
  final SendPort flushSendPort = initData['flushPort'];
  final String modelPath = initData['modelPath'];

  VoiceActivityDetector? vad;
  OfflineRecognizer? recognizer;

  final childReceivePort = ReceivePort();
  mainSendPort.send(childReceivePort.sendPort);

  await for (final message in childReceivePort) {
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

      case _IsolateCommand.accept:
        final data = message['data'] as Uint8List;
        final samples = RecognizerServiceSherpa.pcm16ToFloat32(data);
        vad?.acceptWaveform(samples);
        _processVad(vad, recognizer, mainSendPort);
        break;

      case _IsolateCommand.flush:
        vad?.flush();
        _processVad(vad, recognizer, mainSendPort);
        flushSendPort.send(true);
        break;

      case _IsolateCommand.stop:

        // Логика остановки
        break;
    }
  }
}

/// Вспомогательная функция внутри изолята для обработки сегментов
void _processVad(VoiceActivityDetector? vad, OfflineRecognizer? recognizer, SendPort replyPort) {
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
      replyPort.send(text); // Отправляем текст в главный поток
    }
  }
}
