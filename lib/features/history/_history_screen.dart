import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/dialer/dialer_overlay.dart';
import 'package:coldcall/features/history/deal_card.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/history_sync/_history_sync_screen.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = di<Storage>();
  final _model = di<HistoryVm>();

  @override
  void dispose() {
    _model.stopAndDisposeAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _storage,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            final deals = _storage.deals.toList();
            return PopScope(
              canPop: !(_model.isDialerShown || _model.isEditing),
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  if (_model.isDialerShown) {
                    _model.dialerOverlayModel?.closeDialer(false);
                  } else if (_model.isEditing) {
                    _model.cancelEditing();
                  }
                }
              },
              child: Scaffold(
                appBar: AppBar(
                  title: (_storage.lastSyncStatus.lastSyncTime != null)
                      ? Column(
                          mainAxisSize: .min,
                          crossAxisAlignment: .start,
                          children: [
                            Text('Синхронизировано', style: TextStyle(fontSize: 15)),
                            Text(timeDateFormat.format(_storage.lastSyncStatus.lastSyncTime!), style: TextStyle(fontSize: 14)),
                          ],
                        )
                      : Text('Настроить синхронизацию:'),
                  actions: [IconButton(onPressed: () => showHistorySyncScreen(context), icon: Icon(Icons.sync))],
                ),
                body: (deals.isEmpty)
                    ? Center(child: Text('История пуста'))
                    : SafeArea(
                        child: Stack(
                          children: [
                            RefreshIndicator(
                              onRefresh: () async {
                                _model.cancelMovingHistoryRecord();
                                await _storage.init();
                              },
                              child: ListView.builder(
                                controller: _model.scroller,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: deals.length,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  final deal = deals[deals.length - 1 - index];
                                  return DealCard(deal: deal, key: Key(deal.id));
                                },
                              ),
                            ),

                            // Редактор одного поля Deal или HistoryRecord
                            if (_model.isEditing)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withAlpha(100),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _model.cancelEditing,
                                          child: Container(color: Colors.transparent),
                                        ),
                                      ),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                                        child: Container(
                                          padding: .fromLTRB(15, 10, 15, 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          child: Column(
                                            children: [
                                              TextField(
                                                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                                                controller: _model.editingController,
                                                autofocus: true,
                                                minLines: 2,
                                                maxLines: 5,
                                                // textInputAction: TextInputAction.done,
                                                // onSubmitted: _saveTitleEditing,
                                              ),
                                              Gap(5),
                                              Row(
                                                mainAxisAlignment: .spaceEvenly,
                                                children: [
                                                  TextButton(onPressed: _model.cancelEditing, child: Text('Отменить')),
                                                  TextButton(onPressed: _model.stopEditing, child: Text('Сохранить')),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // // Панель набора номера с полноэкранным оверлеем
                            if (_model.isDialerShown) DialerOverlay(model: _model.dialerOverlayModel!),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm ');
final timeDateFormat = DateFormat('HH:mm dd.MM.yyyy');

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutesм $secondsс';
}
