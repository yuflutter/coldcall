import 'dart:async';
import 'dart:io';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/show_toastification.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:coldcall/features/dialer/dialer_vm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HistoryVm with SimpleChangeNotifier {
  // раскрытие карточки Deal
  Deal? _currentExpandedDeal;
  String? get currentExpandedDealId => _currentExpandedDeal?.id;

  void expandCollapseDealCard(Deal deal, {bool forceExpand = false}) {
    notify(() => _currentExpandedDeal = (_currentExpandedDeal != deal || forceExpand) ? deal : null);
  }

  // аудиоплеер
  _AudioSession? _audioSession;
  String? get currentPlayingRecordId => _audioSession?.currentPlayingRecord.id;
  bool get isAudioPaused => _audioSession?.isPaused ?? false;
  Duration get currentPlayingPosition => _audioSession?.position ?? Duration.zero;
  Duration get currentPlayingDuration => _audioSession?.duration ?? Duration.zero;

  // дозвонщик
  DialerVm? dialerOverlayModel;
  bool get isDialerShown => (dialerOverlayModel != null);

  Future<void> startStopAudio(BuildContext context, HistoryRecord record) async {
    try {
      if (currentPlayingRecordId == record.id) {
        await stopAndDisposeAudio();
      } else {
        await stopAndDisposeAudio();
        _audioSession = _AudioSession(parent: this, currentPlayingRecord: record, onPlayComplete: stopAndDisposeAudio);
        notifyListeners();
        await _audioSession!.startAudio();
      }
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> pauseResumeAudio() async {
    await _audioSession?.pauseResumeAudio();
  }

  Future<void> seekAudioTo(Duration position) async {
    await _audioSession?.seekTo(position);
  }

  Future<void> stopAndDisposeAudio() async {
    await _audioSession?.stopAudio();
    await _audioSession?.dispose();
    notify(() => _audioSession = null);
  }

  Future<void> downloadAudio(HistoryRecord record) async {
    final file = File(await record.audioFilePath()!);
    final bytes = await file.readAsBytes();
    final fileName =
        record.startTime.toIso8601String().substring(0, 16).replaceFirst('T', ' ') + '.' + record.audioFileName!.split('.').last;
    await FilePicker.platform.saveFile(dialogTitle: 'Сохранить аудиозапись', fileName: fileName, bytes: bytes);
  }

  void showDialer(BuildContext context, {required Deal deal, PhoneNumber? phoneNumber}) {
    notify(
      () => dialerOverlayModel = DialerVm(
        initialPhone: phoneNumber,
        deal: deal,
        closeFromOutside: (isCallEnded) => _closeDialer(context, isCallEnded, deal),
      ),
    );
  }

  void _closeDialer(BuildContext context, bool isCallEnded, Deal deal) async {
    notify(() => dialerOverlayModel = null);
    if (isCallEnded) {
      expandCollapseDealCard(deal, forceExpand: true);
      if (context.mounted) showToastification(context, 'Звонок сохранен в историю');
    }
  }
}

/// Сессия содержит все переменные, необходимые для сеанса воспроизведения аудиозаписи
/// При старте нового сеанса старая сессия уничтожается, и заменяется на новую.
/// Это предотвращает проблему управления связанным набором переменных, и корректной их очистки в конце каждого сеанса.
class _AudioSession {
  final SimpleChangeNotifier parent;
  final HistoryRecord currentPlayingRecord;
  final VoidCallback onPlayComplete;

  final _player = AudioPlayer();
  late final StreamSubscription _positionSubs;
  late final StreamSubscription _durationSubs;
  late final StreamSubscription _stateSubs;

  var isPaused = false;
  var position = Duration.zero;
  var duration = Duration.zero;

  _AudioSession({required this.parent, required this.currentPlayingRecord, required this.onPlayComplete}) {
    _positionSubs = _player.onPositionChanged.listen((p) => parent.notify(() => position = p));

    _durationSubs = _player.onDurationChanged.listen((d) => parent.notify(() => duration = d));

    _stateSubs = _player.onPlayerStateChanged.listen(
      (state) => switch (state) {
        .paused => parent.notify(() => isPaused = true),
        .playing => parent.notify(() => isPaused = false),
        .completed => onPlayComplete(),
        _ => null,
      },
    );
  }

  Future<void> dispose() async {
    _positionSubs.cancel();
    _durationSubs.cancel();
    _stateSubs.cancel();
    await _player.dispose();
  }

  Future<void> startAudio() async {
    if (currentPlayingRecord.audioFileName != null) {
      await _player.play(DeviceFileSource(await currentPlayingRecord.audioFilePath()!));
    }
  }

  Future<void> pauseResumeAudio() async {
    if (isPaused) {
      await _player.resume();
    } else {
      await _player.pause();
    }
  }

  Future<void> stopAudio() {
    return _player.stop();
  }

  Future<void> seekTo(Duration position) {
    return _player.seek(position);
  }
}
