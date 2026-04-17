import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/simple_future_listenable_builders.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/features/recorder/_recorder_recognizer_vm.dart';
import 'package:coldcall/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RecorderRecognizerScreen extends StatefulWidget {
  final Deal? deal;
  final bool startImmediately;

  const RecorderRecognizerScreen({super.key, this.deal, this.startImmediately = false});

  @override
  State<RecorderRecognizerScreen> createState() => _RecorderRecognizerScreenState();
}

class _RecorderRecognizerScreenState extends State<RecorderRecognizerScreen> {
  late final _model = di<RecorderRecognizerVm>(); // ищем по суперклассу

  late final _initFuture = () async {
    await _model.init();
    if (widget.startImmediately) await _model.startRecording(deal: widget.deal);
  }();

  final _scroller = ScrollController();

  @override
  void dispose() {
    // инициализация нейросети тяжелая, поэтому храним ее в глобальном DI, и не диспозим при удалении экрана
    // _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroller.hasClients) _scroller.jumpTo(_scroller.position.maxScrollExtent);
    });
    return SimpleFutureListenableBuilder(
      initFuture: _initFuture,
      listenable: _model,
      builder: (context, _, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(15),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  if (widget.deal != null) ...[Text('Новая запись в рамках дела:\n${widget.deal!.title}'), Divider()],
                  Spacer(),
                  if (_model.textTranscription.isNotEmpty)
                    SingleChildScrollView(
                      controller: _scroller,
                      child: Text(_model.textTranscription, textAlign: .start, style: TextStyle(fontSize: 15)),
                    )
                  else if (_model.isSessionActive)
                    Text('Говорите, я слушаю...', textAlign: .center, style: TextStyle(fontSize: 15)),
                  // else
                  //   Text('Начните новый сеанс', textAlign: .center, style: TextStyle(fontSize: 15)),
                  Padding(
                    padding: .fromLTRB(20, 35, 20, 20),
                    child: Center(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        alignment: Alignment.center, // Добавляем явное выравнивание
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          // Этот переход заставит кнопки плавно исчезать/появляться,
                          // что поможет AnimatedSize мягче сработать на уменьшение
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: !_model.isSessionActive
                              ? ActionButton(
                                  key: const ValueKey('mic_idle'), // Уникальный ключ
                                  onPressed: () => _model.startRecording(deal: widget.deal),
                                  enabled: !_model.isFlushing,
                                  tooltip: 'Начать запись',
                                  child: const Icon(Icons.mic),
                                )
                              : Row(
                                  key: const ValueKey('recording_controls'), // Уникальный ключ для всей группы
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ActionButton(
                                      onPressed: _showCancelDialog,
                                      enabled: !_model.isFlushing,
                                      tooltip: 'Отменить запись',
                                      child: const Icon(Icons.clear, color: Colors.red),
                                    ),
                                    Spacer(),
                                    ActionButton(
                                      onPressed: _model.isPaused ? _model.resumeRecording : _model.pauseRecording,
                                      enabled: !_model.isFlushing,
                                      tooltip: 'Пауза',
                                      child: (_model.isPaused) ? Icon(Icons.mic) : Icon(Icons.pause, color: Colors.red),
                                    ),
                                    Spacer(),
                                    ActionButton(
                                      onPressed: () => _model.stopRecording(context),
                                      enabled: !_model.isFlushing,
                                      tooltip: 'Завершить и сохранить запись',
                                      child: const Icon(Icons.stop, color: Colors.red),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCancelDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Отменить запись?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text('Вы уверены, что хотите отменить запись?', style: const TextStyle(color: Colors.white70)),
            Gap(10),
            Text('Аудиофайл и текстовая расшифровка не будут сохранены!', style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отменить', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Продолжить')),
        ],
      ),
    );
    if (ok == true) {
      _model.cancelRecording();
    }
  }
}
