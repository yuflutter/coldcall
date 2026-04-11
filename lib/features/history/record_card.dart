import 'package:coldcall/core/di.dart';
import 'package:coldcall/entities/history_record.dart';
import 'package:coldcall/features/history/_history_screen.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class RecordCard extends StatefulWidget {
  final HistoryRecord record;

  const RecordCard({super.key, required this.record});

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  late final _record = widget.record;
  final _model = di<HistoryVm>();
  final _storage = di<Storage>();

  BuildContext? _detailsBottomSheetContext;
  bool get _isDetailsExpanded => (_detailsBottomSheetContext != null);

  var _isEditing = false;
  late final _noteEditController = TextEditingController(text: _record.note);

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _noteEditController.text = _record.note ?? '';
    setState(() => _isEditing = false);
  }

  void _saveEditing(String note) async {
    _record.updateNote(note.trim());
    await _storage.addOrUpdateAndSaveDeal(_record.deal!);
    _cancelEditing();
  }

  void _deleteRecord(HistoryRecord record) {
    _storage.deleteHistoryRecord(record);
    Navigator.pop(context);
    if (_detailsBottomSheetContext != null) {
      Navigator.of(_detailsBottomSheetContext!).pop();
      setState(() => _detailsBottomSheetContext = null);
    }
  }

  void _call(HistoryRecord record) {
    _model.showDialer(context, deal: record.deal!, phoneNumber: record.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final isAudioPlaying = (_model.currentPlayingRecordId == _record.id);

    return ListenableBuilder(
      listenable: _storage,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            return PopScope(
              canPop: !_isEditing,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) _cancelEditing();
              },
              child: Card(
                margin: const EdgeInsets.fromLTRB(20, 3, 0, 3),
                color: Colors.white12,
                child: InkWell(
                  onTap: (_record.textTranscription != null)
                      ? () => _showDetails(_record)
                      : (_record.phoneNumber != null)
                      ? () => _call(_record)
                      : null,
                  onLongPress: () => _showDeleteRecordDialog(context, _record),
                  child: Padding(
                    padding: .fromLTRB(10, 0, 0, 5),
                    child: Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        Row(
                          children: [
                            Row(
                              mainAxisSize: .min,
                              children: [
                                if (_record.phoneNumber != null) Icon(Icons.call, size: 14),
                                if (_record.audioFileName != null) Icon(Icons.mic, size: 17),
                                Gap(8),
                              ],
                            ),
                            _buildTimeDate(_record.startTime),
                            Spacer(),
                            Text(formatDuration(_record.duration), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            Gap(10),

                            if (_record.audioFileName != null) ...[
                              SizedBox(
                                height: 40,
                                child: IconButton(
                                  padding: .zero,
                                  icon: (isAudioPlaying)
                                      ? Icon(Icons.stop_circle, color: Colors.red, size: 30)
                                      : Icon(Icons.play_circle_filled, color: Colors.green, size: 30),
                                  onPressed: () => _model.startStopAudio(context, _record),
                                ),
                              ),
                            ],

                            if (_record.phoneNumber != null)
                              if (!_isEditing)
                                SizedBox(
                                  height: 40,
                                  child: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(onTap: () => _startEditing(), child: Text('Примечание к звонку')),
                                      PopupMenuItem(onTap: null, child: Text('Имя контакта')),
                                    ],
                                  ),
                                )
                              else
                                IconButton(onPressed: _cancelEditing, icon: Icon(Icons.cancel)),
                          ],
                        ),

                        if (isAudioPlaying && !_isDetailsExpanded) AudioPlayerControl(),

                        if (_record.phoneNumber != null) _buildPhoneNumber(_record),

                        if (_record.note != null && !_isEditing)
                          Padding(
                            padding: .fromLTRB(0, 5, 5, 0),
                            child: Text(_record.note!, style: TextStyle(fontSize: 15)),
                          ),
                        if (_isEditing)
                          TextField(
                            controller: _noteEditController,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _saveEditing,
                          ),

                        if (_record.textTranscription != null && _record.phoneNumber != null) Gap(8),

                        if (_record.textTranscription != null)
                          Padding(
                            padding: .fromLTRB(0, 0, 5, 0),
                            child: Text(_record.textTranscription!, maxLines: 3, overflow: .ellipsis, style: TextStyle(fontSize: 15)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(HistoryRecord record) async {
    setState(() => _detailsBottomSheetContext = context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ListenableBuilder(
            listenable: _model,
            builder: (context, _) {
              final isPlaying = _model.currentPlayingRecordId == record.id;
              return Container(
                padding: .fromLTRB(10, 15, 5, 10),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Gap(10),
                    Padding(
                      padding: .fromLTRB(8, 0, 8, 0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  if (isPlaying) AudioPlayerControl(),
                                  Gap(5),
                                  Table(
                                    // Колонки будут иметь ширину самого широкого элемента в них
                                    defaultColumnWidth: IntrinsicColumnWidth(),
                                    //border: TableBorder.all(color: Colors.grey),
                                    children: [
                                      if (record.phoneNumber != null)
                                        _buildTableRow('Номер:', record.phoneNumber?.formattedNumber ?? 'no phone'),
                                      _buildTableRow('Начало:', _buildTimeDate(record.startTime)),
                                      _buildTableRow('Длительность:', formatDuration(record.duration)),
                                    ],
                                  ),
                                  Gap(15),
                                  const Text(
                                    'Расшифровка:',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                if (record.audioFileName != null) ...[
                                  IconButton(
                                    icon: (isPlaying)
                                        ? Icon(Icons.stop_circle, color: Colors.red, size: 30)
                                        : Icon(Icons.play_circle_filled, color: Colors.green, size: 30),
                                    onPressed: () => _model.startStopAudio(context, record),
                                  ),
                                ],
                                Spacer(),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(onTap: () => _model.downloadAudio(record), child: Text('Скачать аудиофайл')),
                                    // PopupMenuItem(onTap: () => _model.improveTranscription(record), child: Text('Улучшить расшифровку')),
                                    PopupMenuItem(onTap: () => _showDeleteRecordDialog(context, record), child: Text('Удалить')),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(10),
                    Expanded(
                      child: Container(
                        padding: .fromLTRB(13, 7, 12, 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: SelectableText(
                            record.textTranscription ??
                                'Расшифровка будет доступна после блютуз-синхронизации со вторым телефоном (с которого велась аудиозапись).',
                            style: TextStyle(
                              color: record.textTranscription != null ? Colors.white70 : Colors.grey[600],
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
    setState(() => _detailsBottomSheetContext = null);
  }

  TableRow _buildTableRow(String label, dynamic value, {VoidCallback? onTap}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
          child: Text(label, style: _labelStyle),
        ),
        SizedBox(width: 10),
        (onTap == null)
            ? Padding(
                padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
                child: (value is Widget) ? value : Text(value.toString(), style: _valueStyle),
              )
            : InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
                  child: (value is Widget) ? value : Text(value.toString(), style: _valueStyle.copyWith(color: Colors.greenAccent)),
                ),
              ),
      ],
    );
  }

  void _showDeleteRecordDialog(BuildContext context, HistoryRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Удалить запись?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Вы уверены, что хотите удалить запись истории от ${timeDateFormat.format(record.startTime)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => _deleteRecord(record),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Отмена')),
        ],
      ),
    );
  }

  Widget _buildPhoneNumber(HistoryRecord record) {
    return InkWell(
      onTap: () => _call(record),
      child: Text(
        record.phoneNumber!.formattedNumber,
        style: const TextStyle(color: Colors.green, fontSize: 17, fontWeight: .bold),
      ),
    );
  }

  Widget _buildTimeDate(DateTime date) {
    return Row(
      mainAxisSize: .min,
      children: [
        Text(
          _onlyTimeFormat.format(date),
          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: .bold),
        ),
        Gap(10),
        Text(_onlyDateFormat.format(date), style: TextStyle(color: Colors.white70, fontSize: 15)),
      ],
    );
  }

  static final _onlyTimeFormat = DateFormat('HH:mm');
  static final _onlyDateFormat = DateFormat('dd.MM.yyyy');
  final _labelStyle = TextStyle(color: Colors.grey[400], fontSize: 16);
  final _valueStyle = TextStyle(color: Colors.white, fontSize: 17);
}

class AudioPlayerControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = di<HistoryVm>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.green,
                  inactiveTrackColor: Colors.grey[700],
                  thumbColor: Colors.green,
                  overlayColor: Colors.green.withAlpha(50),
                  padding: .fromLTRB(0, 0, 10, 0),
                ),
                child: Slider(
                  value: model.currentPlayingPosition.inMilliseconds.toDouble().clamp(
                    0,
                    model.currentPlayingDuration.inMilliseconds.toDouble(),
                  ),
                  max: model.currentPlayingDuration.inMilliseconds > 0 ? model.currentPlayingDuration.inMilliseconds.toDouble() : 1,
                  onChanged: (v) => model.seekAudioTo(Duration(milliseconds: v.toInt())),
                ),
              ),
            ),
            Text(formatDuration(model.currentPlayingPosition), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(model.isAudioPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 28),
              onPressed: model.pauseResumeAudio,
            ),
          ],
        );
      },
    );
  }
}
