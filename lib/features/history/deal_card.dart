import 'package:coldcall/core/di.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/features/history/_history_screen.dart';
import 'package:coldcall/features/history/record_card.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/user_session/_user_session_vm.dart';
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

  var _isTitleEditing = false;
  late final _titleEditController = TextEditingController(text: _deal.title);

  void _cancelTitileEditing() {
    _titleEditController.text = _deal.title;
    setState(() => _isTitleEditing = false);
  }

  void _startTitleEditing() {
    _model.collapseDealCard();
    setState(() => _isTitleEditing = true);
  }

  void _saveTitleEditing([String? title]) async {
    title ??= _titleEditController.text;
    _deal.updateTitle(title.trim());
    setState(() => _isTitleEditing = false);
    if (_model.currentExpandedDealId != _deal.id) _model.collapseDealCard();
    await _storage.addOrUpdateAndSaveDeal(_deal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_model.scroller.hasClients) {
        _model.scroller.jumpTo(0.0);
      }
    });
  }

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
                  onTap: (!_isTitleEditing) ? () => _model.expandCollapseDealCard(_deal) : null,
                  onLongPress: (!_isTitleEditing) ? () => _showDeleteDealDialog(context, _deal) : null,
                  child: PopScope(
                    canPop: !_isTitleEditing,
                    onPopInvokedWithResult: (didPop, result) => (!didPop) ? _cancelTitileEditing() : null,
                    child: Card(
                      margin: .fromLTRB(0, 4, 0, 4),
                      color: Colors.white24,
                      child: Padding(
                        padding: const .fromLTRB(10, 0, 0, 5),
                        child: Column(
                          crossAxisAlignment: .stretch,
                          children: [
                            Row(
                              crossAxisAlignment: .start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: .fromLTRB(0, 7, 0, 0),
                                    child: Stack(
                                      children: [
                                        if (!_isTitleEditing)
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
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                                            child: TextField(
                                              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                                              controller: _titleEditController,
                                              autofocus: true,
                                              minLines: 2,
                                              maxLines: 5,
                                              // textInputAction: TextInputAction.done,
                                              onSubmitted: _saveTitleEditing,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    if (!_isTitleEditing)
                                      PopupMenuButton(
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            onTap: () => _model.showDialer(context, deal: _deal, phoneNumber: _deal.lastPhoneNumber),
                                            child: Text('Позвонить'),
                                          ),
                                          PopupMenuItem(
                                            onTap: () => di<UserSessionVm>().startRecordForDeal(_deal),
                                            child: Text('Записать'),
                                          ),
                                          PopupMenuItem(onTap: _startTitleEditing, child: Text('Изменить описание')),
                                          PopupMenuItem(onTap: () => _showDeleteDealDialog(context, _deal), child: Text('Удалить')),
                                        ],
                                      )
                                    else ...[
                                      IconButton(onPressed: _cancelTitileEditing, icon: Icon(Icons.cancel)),
                                      IconButton(onPressed: _saveTitleEditing, icon: Icon(Icons.save)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding: const .fromLTRB(0, 3, 7, 0),
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

  void _deleteDeal(Deal deal) {
    _storage.deleteDeal(deal);
    Navigator.pop(context);
  }

  static final _dateTextStyle = TextStyle(fontSize: 14, color: Colors.grey);
}
