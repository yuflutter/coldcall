import 'dart:async';
import 'dart:typed_data';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class SherpaUtils {
  static const _modelFolder = 'assets';

  static Future<String> copyAssetsToDocuments(List<String> fileNames) async {
    final dir = (await di<Storage>().storageDir());
    final targetDir = Directory('$dir/$_modelFolder');

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
