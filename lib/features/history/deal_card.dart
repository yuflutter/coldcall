import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/features/history/history_record_card.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/history/history_styles.dart';
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

  void _startTitleEditing() async {
    _model.startEditing(
      initialText: _deal.title,
      onStopEditing: (newText) async {
        try {
          _deal.updateTitle(newText);
          await _storage.addOrUpdateAndSaveDeal(_deal);
          await Future.delayed(Duration(seconds: 1));
          _model.scrollToLastModifiedDeal();
        } catch (e, s) {
          Err.add(e, s);
        }
      },
    );
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
                Builder(
                  builder: (headContext) {
                    return InkWell(
                      onTap: () => _model.expandCollapseDealCard(_deal),
                      onLongPress: () => _showDeleteDealDialog(context, _deal),
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
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
                                          if (_model.isHistoryRecordMoving)
                                            PopupMenuItem(
                                              onTap: () => _model.stopMovingHistoryRecord(_deal),
                                              child: Text('Вставить сюда...'),
                                            ),
                                          PopupMenuItem(onTap: () => _showDeleteDealDialog(context, _deal), child: Text('Удалить')),
                                        ],
                                      ),
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
                    );
                  },
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
    return Column(
      children: [...deal.notDeletedAndSortedRecords.map((record) => HistoryRecordCard(record: record, key: Key(record.id)))],
    );
  }

  void _showDeleteDealDialog(BuildContext context, Deal deal) {
    _model.expandCollapseDealCard(deal, forceSet: true);

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
            if (deal.notDeletedAndSortedRecords.isNotEmpty) ...[
              Gap(15),
              Text(
                'Внимание!!!\nДело содержит ${deal.notDeletedAndSortedRecords.length} записей истории!',
                style: TextStyle(color: Colors.red),
              ),
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
