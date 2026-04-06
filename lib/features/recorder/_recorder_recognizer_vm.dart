import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/_all_syncable_entities.dart';
import 'package:flutter/material.dart';

/// Абстрактная вью-модель для одновременной записи аудио и распознавания речи в текст.
abstract class RecorderRecognizerVm with SimpleChangeNotifier {
  bool get isSessionActive;
  bool get isPaused;
  bool get isFlushing;

  String get textTranscription;

  Future<void> init();

  Future<void> startRecording({Deal? deal});

  Future<void> pauseRecording();

  Future<void> resumeRecording();

  Future<void> cancelRecording();

  Future<void> stopRecording(BuildContext context);
}
