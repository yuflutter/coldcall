import 'dart:async';
import 'dart:typed_data';
import 'package:coldcall/features/recorder/recognizer_service_sherpa.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

/// Инференс модели синхронный, выполняется в главном треде, поэтому немного фризит интерфейс.
/// Смотри асинхронную версию (на изоляте).
class RecognizerServiceSherpaSync extends RecognizerServiceSherpa {
  var _isInited = false;

  late final VoiceActivityDetector _vad;
  late final OfflineRecognizer _recognizer;

  _Session? _session;

  @override
  bool get isSessionActive => (_session != null);

  @override
  String get textTranscription => (_session != null) ? _session!.textTranscription.toString() : '';

  @override
  void dispose() {
    if (_isInited) {
      _recognizer.free();
      _vad.free();
    }
    super.dispose();
  }

  /// Ининицализация нейросети тяжелая, поэтому храним в глобальном DI и инициализируем лениво только один раз
  @override
  Future<void> init() async {
    if (!_isInited) {
      initBindings();

      final modelPath = await copyAssetsToDocuments();

      // Silero VAD — детектирует паузы и нарезает сегменты
      _vad = VoiceActivityDetector(
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
          debug: false,
        ),
        bufferSizeInSeconds: 30,
      );

      // GigaAM v2 — NeMo CTC offline
      _recognizer = OfflineRecognizer(
        OfflineRecognizerConfig(
          model: OfflineModelConfig(
            nemoCtc: OfflineNemoEncDecCtcModelConfig(model: '$modelPath/model.int8.onnx'),
            tokens: '$modelPath/tokens.txt',
            numThreads: 2,
            debug: false,
          ),
          decodingMethod: 'greedy_search',
        ),
      );

      _isInited = true;
    }

    disposeSession();
  }

  @override
  void startSession() {
    notify(() => _session = _Session());
  }

  @override
  FutureOr<void> flushSession() async {
    // обрабатываем хвост (речь без финальной паузы)
    _vad.flush();
    // распознаем сегменты
    _recognizeVadSegments();
  }

  @override
  Future<void> disposeSession() async {
    notify(() => _session = null);
  }

  @override
  FutureOr<void> acceptWaveform(Uint8List audioChunk) async {
    // скармливаем чанки в VAD
    _vad.acceptWaveform(RecognizerServiceSherpa.pcm16ToFloat32(audioChunk));
    // распознаем сегменты
    _recognizeVadSegments();
  }

  // Получаем из VAD сегменты, и распознаем каждый
  void _recognizeVadSegments() {
    while (!_vad.isEmpty()) {
      final segment = _vad.front();
      _vad.pop();

      final offlineStream = _recognizer.createStream();
      offlineStream.acceptWaveform(samples: segment.samples, sampleRate: 16000);
      _recognizer.decode(offlineStream);
      final text = _recognizer.getResult(offlineStream).text.trim();
      offlineStream.free();

      if (text.isNotEmpty) {
        notify(() => _session!.textTranscription.write(text));
      }
    }
  }
}

class _Session {
  final textTranscription = StringBuffer();
}
