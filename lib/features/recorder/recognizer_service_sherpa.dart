// import 'dart:async';
// import 'dart:typed_data';
// import 'package:coldcall/features/recorder/recognizer_service.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// // import 'package:archive/archive_io.dart';

// /// Реализация на базе GigaAM v2 (Sber/NeMo CTC) + Silero VAD.
// /// Модели (~228 MB суммарно):
// ///  assets/giga-am-v2/model.int8.onnx  — скачать из:
// ///  https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-ctc-giga-am-v2-russian-2025-04-19.tar.bz2
// ///  assets/giga-am-v2/tokens.txt       — из того же архива
// ///  assets/giga-am-v2/silero_vad.onnx  — скачать из:
// ///  https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx
// abstract class RecognizerServiceSherpa extends RecognizerService {
//   final _modelFolder = 'assets';
//   final _modelFiles = ['model.int8.onnx', 'tokens.txt', 'silero_vad.onnx'];
//   // static const _modelZipPath = 'assets/giga-am-v2.zip';

//   Future<String> copyAssetsToDocuments() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final targetDir = Directory('${dir.path}/$_modelFolder');

//     if (!await targetDir.exists()) {
//       await targetDir.create(recursive: true);
//     }

//     for (final fileName in _modelFiles) {
//       final targetFile = File('${targetDir.path}/$fileName');
//       if (!await targetFile.exists()) {
//         final data = await rootBundle.load('$_modelFolder/$fileName');
//         await targetFile.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
//       }
//     }

//     return targetDir.path;
//   }

//   // static Future<String> unzipAssetsToDocuments() async {
//   //   final dir = await getApplicationDocumentsDirectory();
//   //   final targetDir = Directory('${dir.path}/$_modelFolder');

//   //   // Если папка уже существует, можно пропустить распаковку (или проверять флаг)
//   //   if (!await targetDir.exists()) {
//   //     await targetDir.create(recursive: true);
//   //   }

//   //   // 1. Загружаем архив как байты
//   //   final data = await rootBundle.load(_modelZipPath);
//   //   final bytes = data.buffer.asUint8List();

//   //   // 2. Декодируем ZIP
//   //   final archive = ZipDecoder().decodeBytes(bytes);

//   //   // 3. Проходим по всем файлам в архиве
//   //   for (final file in archive) {
//   //     final filename = file.name;
//   //     if (file.isFile) {
//   //       final data = file.content as List<int>;
//   //       final outFile = File('${targetDir.path}/$filename');

//   //       // Создаем подпапки, если они есть внутри архива
//   //       await outFile.create(recursive: true);
//   //       await outFile.writeAsBytes(data);
//   //     }
//   //   }
//   //   return targetDir.path;
//   // }

//   static Float32List pcm16ToFloat32(Uint8List bytes) {
//     // Копируем в выровненный буфер, чтобы избежать RangeError при нечётном offsetInBytes
//     final aligned = Uint8List.fromList(bytes);
//     final int16 = aligned.buffer.asInt16List();
//     final float32 = Float32List(int16.length);
//     for (var i = 0; i < int16.length; i++) {
//       float32[i] = int16[i] / 32768.0;
//     }
//     return float32;
//   }
// }
