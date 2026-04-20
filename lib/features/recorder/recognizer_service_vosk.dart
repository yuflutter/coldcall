import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:coldcall/features/recorder/recognizer_service.dart';
import 'package:vosk_flutter_service/vosk_flutter.dart';

/// Быстрая реализация на основе облегченной стриминговой модели:
///   https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip
/// Очень быстро работает, малый вес(45 MB), асинхронный API, почти не грузит процессор,
/// но недостаточно точный инференс. А полная модель vosk весит неприемлемо много для мобилки
class RecognizerServiceVosk extends RecognizerService {
  static const _modelPath = 'assets/vosk-model-small-ru-0.22.zip';

  var _isInited = false;

  late final Model _model;
  late final Recognizer _recognizer;

  _Session? _session;

  @override
  bool get isSessionActive => (_session != null);

  @override
  String get textTranscription => (_session != null) ? _session!.textTranscriptionFinal + _session!.textTranscriptionCurrent : '';

  @override
  void dispose() {
    _recognizer.dispose();
    _model.dispose();
    super.dispose();
  }

  /// Ининицализация нейросети тяжелая, поэтому храним в глобальном DI и инициализируем лениво только один раз
  @override
  Future<void> init() async {
    if (!_isInited) {
      final vosk = VoskFlutterPlugin.instance();
      final modelPath = await ModelLoader().loadFromAssets(_modelPath);

      _model = await vosk.createModel(modelPath);
      _recognizer = await vosk.createRecognizer(model: _model, sampleRate: 16000);

      _isInited = true;
    }

    disposeSession();
  }

  @override
  void startSession() {
    notify(() => _session = _Session());
  }

  @override
  Future<void> flushSession() async {
    // обрабатываем хвост (речь без финальной паузы)
    // TODO: помедитировать здесь, при некоторых условиях похоже хвост речи обрезается
    final res = jsonDecode(await _recognizer.getFinalResult())['text'] as String;
    if (res.isNotEmpty) {
      _session!.textTranscriptionFinal += '$res ';
      _session!.textTranscriptionCurrent = '';
    }
  }

  @override
  void disposeSession() async {
    notify(() => _session = null);
  }

  @override
  FutureOr<void> acceptWaveform(Uint8List audioChunk) async {
    // Отправляем в Vosk, и сразу получаем результат
    bool isFound = await _recognizer.acceptWaveformBytes(audioChunk);
    if (isFound) {
      final res = jsonDecode(await _recognizer.getResult())['text'] as String;
      if (res.isNotEmpty) {
        _session!.textTranscriptionFinal += '$res ';
        _session!.textTranscriptionCurrent = '';
      }
    } else {
      final res = jsonDecode(await _recognizer.getPartialResult())['partial'] as String;
      if (res.isNotEmpty) {
        _session!.textTranscriptionCurrent = res;
      }
    }
  }
}

class _Session {
  String textTranscriptionFinal = '';
  String textTranscriptionCurrent = '';
}
