import 'dart:isolate';
import 'package:coldcall/features/recorder/sherpa_utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

// Функция для однократного распознавания аудиофайла с диска.
// Чтобы она реально заработала - сначала нужно в исходном аудиофайле сделать компрессию,
// подняв громкость голоса собеседника, который просачивается из громкого телефона.
// Сейчас распознавание файла почти не улучшает текст по сравнению со стримминговым распознаванием.
Future<String> recognizeFile(String filePath) async {
  final modelPath = await SherpaUtils.copyAssetsToDocuments(['model.int8.onnx', 'tokens.txt']);

  return await Isolate.run(() => _recognizeFile(modelPath, filePath));
}

Future<String> _recognizeFile(String modelPath, String filePath) async {
  initBindings();

  final wave = readWave(filePath);
  if (wave.samples.isEmpty) throw 'Не удалось прочитать файл: $filePath';

  // final bytes = await File(filePath).readAsBytes();
  // // Пропускаем ровно 44 байта вашего заголовка
  // final int16Data = bytes.buffer.asInt16List(44);
  // final float32Samples = Float32List.fromList(int16Data.map((x) => x / 32768.0).toList());

  // Log.deb(File('$modelPath/model.int8.onnx').existsSync());
  // Log.deb(File('$modelPath/tokens.txt').existsSync());

  final recognizer = OfflineRecognizer(
    OfflineRecognizerConfig(
      model: OfflineModelConfig(
        nemoCtc: OfflineNemoEncDecCtcModelConfig(model: '$modelPath/model.int8.onnx'),
        tokens: '$modelPath/tokens.txt',
        numThreads: 4,
        debug: false,
      ),
      decodingMethod: 'greedy_search',
    ),
  );

  // Конфиг для модели SenseVoiceSmall, но она не заработала, похоже русский не понимает
  // final recognizer = OfflineRecognizer(
  //   OfflineRecognizerConfig(
  //     model: OfflineModelConfig(
  //       senseVoice: OfflineSenseVoiceModelConfig(
  //         model: '$modelPath/model.int8.onnx',
  //         language: '', // Пустая строка заставляет модель саму найти язык
  //         useInverseTextNormalization: true,
  //       ),
  //       tokens: '$modelPath/tokens.txt',
  //       numThreads: 4,
  //       debug: true,
  //     ),
  //     decodingMethod: 'greedy_search',
  //   ),
  // );

  final stream = recognizer.createStream();
  stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);

  recognizer.decode(stream);
  final result = recognizer.getResult(stream).text.trim();

  stream.free();
  recognizer.free();

  return result;
}
