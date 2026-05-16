import 'dart:async';
import 'dart:io';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecorderResult {
  final String audioFilePath;
  final DateTime startTime;
  final Duration duration;
  RecorderResult({required this.audioFilePath, required this.startTime, required this.duration});
}

/// Одноразовая сессия звукозаписи. После остановки записи - владельцу нужно создавать новую сессию.
/// Одновременно пишет в файл, и возвращает аудио-стрим для аудио-детекторов и онлайн-рекогнайзеров.
class RecorderSession {
  // Формат, пригодный для нейросетей.
  static const _audioRecorderConfig = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1);
  static const _audioFileExt = 'wav';

  final _recorder = AudioRecorder();

  late final DateTime _startTime;
  late final String _audioFilePath;

  late final StreamSubscription<Uint8List> _audioStreamSubs;

  late final IOSink _fileSink;
  int _audioDataBytes = 0;

  void dispose() {
    _audioStreamSubs.cancel();
    _recorder.dispose();
    _fileSink.close();
  }

  /// Начинает запись в файл, возвращает аудиострим для онлайн-рекогнайзера
  Future<Stream<Uint8List>> startRecording() async {
    if (!Platform.isLinux && !kIsWeb) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) throw 'Разрешение к микрофону не предоставлено';
    }
    final dir = (await di<Storage>().storageDir());
    _startTime = DateTime.now();
    _audioFilePath = '$dir/audio_${_startTime.microsecondsSinceEpoch}.$_audioFileExt';

    // Открываем файл и пишем placeholder-заголовок (размер допишем при остановке)
    _fileSink = File(_audioFilePath).openWrite();
    _fileSink.add(_buildWavHeader(0)); // placeholder, перезапишем потом
    _audioDataBytes = 0;

    final audioStream = (await _recorder.startStream(_audioRecorderConfig)).asBroadcastStream();

    _audioStreamSubs = audioStream.listen((audioChunk) async {
      // Пишем PCM-заголовок в файл
      _fileSink.add(audioChunk);
      _audioDataBytes += audioChunk.length;
    });

    return audioStream;
  }

  Future<void> pauseRecording() async {
    await _recorder.pause();
  }

  Future<void> resumeRecording() async {
    await _recorder.resume();
  }

  Future<RecorderResult> stopRecording() async {
    await _recorder.stop();

    // Закрываем sink и перезаписываем заголовок с правильным размером
    await _fileSink.flush();
    await _patchWavHeader(_audioFilePath, _audioDataBytes);

    return RecorderResult(audioFilePath: _audioFilePath, startTime: _startTime, duration: DateTime.now().difference(_startTime));
  }
}

/// Строит 44-байтный WAV-заголовок для PCM 16bit mono 16000Hz
Uint8List _buildWavHeader(int dataSize) {
  const int sampleRate = 16000;
  const int numChannels = 1;
  const int bitsPerSample = 16;
  final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final int blockAlign = numChannels * bitsPerSample ~/ 8;

  final header = ByteData(44);
  // RIFF chunk
  header.setUint8(0, 0x52); // R
  header.setUint8(1, 0x49); // I
  header.setUint8(2, 0x46); // F
  header.setUint8(3, 0x46); // F
  header.setUint32(4, 36 + dataSize, Endian.little); // ChunkSize
  header.setUint8(8, 0x57); // W
  header.setUint8(9, 0x41); // A
  header.setUint8(10, 0x56); // V
  header.setUint8(11, 0x45); // E
  // fmt chunk
  header.setUint8(12, 0x66); // f
  header.setUint8(13, 0x6D); // m
  header.setUint8(14, 0x74); // t
  header.setUint8(15, 0x20); // (space)
  header.setUint32(16, 16, Endian.little); // Subchunk1Size (PCM = 16)
  header.setUint16(20, 1, Endian.little); // AudioFormat (PCM = 1)
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  // data chunk
  header.setUint8(36, 0x64); // d
  header.setUint8(37, 0x61); // a
  header.setUint8(38, 0x74); // t
  header.setUint8(39, 0x61); // a
  header.setUint32(40, dataSize, Endian.little); // Subchunk2Size

  return header.buffer.asUint8List();
}

/// Перезаписывает размеры в уже записанном WAV-файле
/// TODO: Оптимизировать, если возможна прямая запись в файл
Future<void> _patchWavHeader(String path, int dataSize) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final patched = Uint8List.fromList(bytes);
  final bd = ByteData.sublistView(patched);
  bd.setUint32(4, 36 + dataSize, Endian.little); // RIFF ChunkSize
  bd.setUint32(40, dataSize, Endian.little); // data Subchunk2Size
  await file.writeAsBytes(patched);
}
