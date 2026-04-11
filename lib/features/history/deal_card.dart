import 'package:coldcall/core/di.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/features/history/_history_screen.dart';
import 'package:coldcall/features/history/record_card.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/user_session/user_session_vm.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DealCard extends StatefulWidget {
  final Deal deal;

  const DealCard({super.key, required this.deal});

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  late final _deal = widget.deal;
  final _model = di<HistoryVm>();
  final _storage = di<Storage>();

  var _isEditing = false;
  late final _titleEditController = TextEditingController(text: _deal.title);

  static final _dateTextStyle = TextStyle(fontSize: 14, color: Colors.grey);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _storage,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            return Column(
              children: [
                InkWell(
                  onTap: () => _model.expandCollapseDealCard(_deal),
                  onLongPress: () => _showDeleteDealDialog(context, _deal),
                  child: PopScope(
                    canPop: !_isEditing,
                    onPopInvokedWithResult: (didPop, result) {
                      if (!didPop) _cancelEditing();
                    },
                    child: Card(
                      margin: .fromLTRB(0, 4, 0, 4),
                      color: Colors.white24,
                      child: Padding(
                        padding: const .fromLTRB(10, 7, 0, 7),
                        child: Column(
                          crossAxisAlignment: .stretch,
                          children: [
                            Row(
                              crossAxisAlignment: .start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      if (!_isEditing)
                                        RichText(
                                          // maxLines: 3,
                                          // overflow: .ellipsis,
                                          text: TextSpan(
                                            children: [
                                              WidgetSpan(
                                                child: Row(
                                                  mainAxisSize: .min,
                                                  children: [
                                                    if (_deal.hasCalls) Icon(Icons.call, size: 14),
                                                    if (_deal.hasAudios) Icon(Icons.mic, size: 17),
                                                    if (_deal.hasCalls || _deal.hasAudios) Gap(8),
                                                  ],
                                                ),
                                              ),
                                              TextSpan(text: _deal.title, style: TextStyle(fontSize: 15)),
                                            ],
                                          ),
                                        )
                                      else
                                        TextField(
                                          controller: _titleEditController,
                                          autofocus: true,
                                          minLines: 2,
                                          maxLines: 5,
                                          // textInputAction: TextInputAction.done,
                                          onSubmitted: _saveEditing,
                                        ),
                                    ],
                                  ),
                                ),
                                if (!_isEditing)
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        onTap: () => _model.showDialer(context, deal: _deal, phoneNumber: _deal.lastPhoneNumber),
                                        child: Text('Позвонить'),
                                      ),
                                      PopupMenuItem(onTap: () => di<UserSessionVm>().startRecordForDeal(_deal), child: Text('Записать')),
                                      PopupMenuItem(onTap: () => setState(() => _isEditing = true), child: Text('Редактировать заголовок')),
                                      PopupMenuItem(onTap: () => _showDeleteDealDialog(context, _deal), child: Text('Удалить')),
                                    ],
                                  )
                                else ...[
                                  IconButton(onPressed: _saveEditing, icon: Icon(Icons.save)),
                                  IconButton(onPressed: _cancelEditing, icon: Icon(Icons.cancel)),
                                ],
                              ],
                            ),
                            Padding(
                              padding: const .fromLTRB(0, 0, 5, 0),
                              child: Row(
                                children: [
                                  Text(dateTimeFormat.format(_deal.created), style: _dateTextStyle),
                                  Spacer(),
                                  if (_deal.lastModified != _deal.created)
                                    Text(dateTimeFormat.format(_deal.lastModified), style: _dateTextStyle),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_model.currentExpandedDealId == _deal.id) _buildDealRecordsList(_deal),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDealRecordsList(Deal deal) {
    return Column(children: [...deal.records.map((record) => RecordCard(record: record))]);
  }

  void _showDeleteDealDialog(BuildContext context, Deal deal) {
    _model.expandCollapseDealCard(deal, forceExpand: true);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Удалить дело?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              'Вы уверены, что хотите удалить дело от ${timeDateFormat.format(deal.created)}?',
              style: const TextStyle(color: Colors.white70),
            ),
            if (deal.records.isNotEmpty) ...[
              Gap(15),
              Text('Внимание!!!\nДело содержит ${deal.records.length} записей истории!', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _deleteDeal(deal),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Отмена')),
        ],
      ),
    );
  }

  void _cancelEditing() {
    _titleEditController.text = _deal.title;
    setState(() => _isEditing = false);
  }

  void _saveEditing([String? title]) async {
    title ??= _titleEditController.text;
    _deal.updateTitle(title.trim());
    setState(() => _isEditing = false);
    await _storage.addOrUpdateAndSaveDeal(_deal);
  }

  void _deleteDeal(Deal deal) {
    _storage.deleteDeal(deal);
    Navigator.pop(context);
  }
}
