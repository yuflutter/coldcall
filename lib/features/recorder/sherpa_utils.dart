import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SherpaUtils {
  static const _modelFolder = 'assets';

  static Future<String> copyAssetsToDocuments(List<String> fileNames) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${dir.path}/$_modelFolder');

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    for (final fileName in fileNames) {
      final targetFile = File('${targetDir.path}/$fileName');
      if (!await targetFile.exists()) {
        final data = await rootBundle.load('$_modelFolder/$fileName');
        await targetFile.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
    }

    return targetDir.path;
  }

  static Float32List pcm16ToFloat32(Uint8List bytes) {
    // Копируем в выровненный буфер, чтобы избежать RangeError при нечётном offsetInBytes
    final aligned = Uint8List.fromList(bytes);
    final int16 = aligned.buffer.asInt16List();
    final float32 = Float32List(int16.length);
    for (var i = 0; i < int16.length; i++) {
      float32[i] = int16[i] / 32768.0;
    }
    return float32;
  }
}
