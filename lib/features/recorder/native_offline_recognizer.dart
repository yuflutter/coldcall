// import 'dart:io';
// import 'package:flutter/services.dart';

// class NativeOfflineRecognizer {
//   static const platform = MethodChannel('com.example.coldcall/audio_transcriber');

//   /// ЭТА ХРЕНЬ НЕ РАБОТАЕТ, ДОРАБОТАТЬ КОГДА-НИБУДЬ
//   /// Транскрибирует аудиофайл используя встроенный Speech Recognition API
//   /// Работает локально на Android (если установлены языковые модели)
//   Future<String?> transcribeAudio(String audioPath) async {
//     if (!Platform.isAndroid) {
//       print('Audio transcription is only supported on Android');
//       return null;
//     }

//     try {
//       final String? result = await platform.invokeMethod('transcribeAudio', {'audioPath': audioPath});
//       return result;
//     } on PlatformException catch (e) {
//       print('Failed to transcribe audio: ${e.message}');
//       return null;
//     } catch (e) {
//       print('Unexpected error during transcription: $e');
//       return null;
//     }
//   }
// }
