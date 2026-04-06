import 'dart:async';
import 'dart:typed_data';

import 'package:coldcall/core/simple_change_notifier.dart';

/// Абстрактный сервис для распознавания речи в текст.
/// Доступно несколько реализаций на базе различных нейросетей, инжектятся в app_config.dart
abstract class RecognizerService with SimpleChangeNotifier {
  bool get isSessionActive;
  String get textTranscription;

  Future<void> init();

  void startSession();

  FutureOr<void> flushSession();

  void disposeSession();

  FutureOr<void> acceptWaveform(Uint8List audioChunk);
}
