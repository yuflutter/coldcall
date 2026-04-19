import 'dart:isolate';

import 'package:coldcall/features/recorder/sherpa_utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

// Функция для однократного распознавания аудиофайла с диска.
// Реализация на базе SenseVoiceSmall, скачать отсюда:
// https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/tree/main
Future<String> recognizeFile(String filePath) async {
  final modelPath = await SherpaUtils.copyAssetsToDocuments(['model.int8.onnx', 'tokens.txt']);

  return await Isolate.run(() => _recognizeFile(modelPath, filePath));
}

Future<String> _recognizeFile(String modelPath, String filePath) async {
  initBindings();

  final wave = readWave(filePath);
  if (wave.samples.isEmpty) throw 'Не удалось прочитать файл: $filePath';

  final recognizer = OfflineRecognizer(
    OfflineRecognizerConfig(
      model: OfflineModelConfig(
        senseVoice: OfflineSenseVoiceModelConfig(model: '$modelPath/model.int8.onnx', language: 'ru', useInverseTextNormalization: true),
        tokens: '$modelPath/tokens.txt',
        numThreads: 4,
        debug: true,
      ),
      decodingMethod: 'greedy_search',
    ),
  );

  final stream = recognizer.createStream();
  stream.acceptWaveform(samples: wave.samples, sampleRate: 16000);
  recognizer.decode(stream);
  final result = recognizer.getResult(stream).text.trim();

  stream.free();
  recognizer.free();

  return result;
}

// /// Параметры, передаваемые в изолят
// class _RecognizeFileParams {
//   const _RecognizeFileParams({required this.filePath, required this.modelPath, required this.punctModelPath});

//   final String filePath;
//   final String modelPath;

//   /// Путь к ct-transformer модели пунктуатора (опционально).
//   /// Если пустой — пунктуация не добавляется.
//   final String punctModelPath;
// }

// /// Сервис для однократного распознавания аудиофайла с диска.
// ///
// /// Использует те же модели (GigaAM v2 + Silero VAD), что и стриминговый сервис.
// /// Инференс выполняется в отдельном изоляте через [Isolate.run], чтобы не
// /// блокировать UI-поток.
// ///
// /// Пунктуатор подключается опционально: если файл модели существует по пути
// /// [punctModelPath], он будет применён к итоговому тексту.
// class FileRecognizerService extends RecognizerServiceSherpa {
//   /// Распознать WAV-файл по [filePath].
//   ///
//   /// [punctModelPath] — путь к ct-transformer ONNX-модели пунктуатора.
//   /// Если не передан или файл не найден — пунктуация пропускается.
//   ///
//   /// Возвращает распознанный текст (с пунктуацией, если модель доступна).
//   Future<String> recognizeFile(String filePath, {String punctModelPath = ''}) async {
//     final modelPath = await copyAssetsToDocuments();

//     final params = _RecognizeFileParams(filePath: filePath, modelPath: modelPath, punctModelPath: punctModelPath);

//     return Isolate.run(() => _recognizeFileInIsolate(params));
//   }

// /// Вся тяжёлая работа выполняется здесь — внутри изолята.
// String _recognizeFileInIsolate(_RecognizeFileParams params) {
//   initBindings();

//   // --- Читаем WAV-файл ---
//   final wave = readWave(params.filePath);
//   if (wave.samples.isEmpty) {
//     throw Exception('Не удалось прочитать файл: ${params.filePath}');
//   }

//   // --- VAD ---
//   final vad = VoiceActivityDetector(
//     config: VadModelConfig(
//       sileroVad: SileroVadModelConfig(
//         model: '${params.modelPath}/silero_vad.onnx',
//         threshold: 0.4,
//         minSilenceDuration: 0.4,
//         minSpeechDuration: 0.25,
//         windowSize: 512,
//       ),
//       sampleRate: 16000,
//       numThreads: 1,
//       debug: false,
//     ),
//     bufferSizeInSeconds: 60,
//   );

//   // --- Распознаватель ---
//   final recognizer = OfflineRecognizer(
//     OfflineRecognizerConfig(
//       model: OfflineModelConfig(
//         nemoCtc: OfflineNemoEncDecCtcModelConfig(model: '${params.modelPath}/model.int8.onnx'),
//         tokens: '${params.modelPath}/tokens.txt',
//         numThreads: 4,
//         debug: false,
//       ),
//       decodingMethod: 'greedy_search',
//     ),
//   );

//   // --- Прогоняем сэмплы через VAD ---
//   // Подаём чанками по 512 сэмплов (размер окна Silero VAD)
//   const chunkSize = 512;
//   final samples = wave.samples;
//   for (var offset = 0; offset < samples.length; offset += chunkSize) {
//     final end = (offset + chunkSize).clamp(0, samples.length);
//     vad.acceptWaveform(samples.sublist(offset, end));
//   }
//   vad.flush(); // обрабатываем хвост

//   // --- Распознаём каждый VAD-сегмент ---
//   final buffer = StringBuffer();
//   while (!vad.isEmpty()) {
//     final segment = vad.front();
//     vad.pop();

//     final stream = recognizer.createStream();
//     stream.acceptWaveform(samples: segment.samples, sampleRate: 16000);
//     recognizer.decode(stream);
//     final text = recognizer.getResult(stream).text.trim();
//     stream.free();

//     if (text.isNotEmpty) {
//       if (buffer.isNotEmpty) buffer.write(' ');
//       buffer.write(text);
//     }
//   }

//   recognizer.free();
//   vad.free();

//   var result = buffer.toString();

//   // --- Пунктуатор (опционально) ---
//   if (params.punctModelPath.isNotEmpty && result.isNotEmpty) {
//     try {
//       final punct = OfflinePunctuation(
//         config: OfflinePunctuationConfig(
//           model: OfflinePunctuationModelConfig(ctTransformer: params.punctModelPath, numThreads: 2, debug: false),
//         ),
//       );
//       result = punct.addPunct(result);
//       punct.free();
//     } catch (_) {
//       // Если модель не загрузилась — возвращаем текст без пунктуации
//     }
//   }

//   return result;
// }
