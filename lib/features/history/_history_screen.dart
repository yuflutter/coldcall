import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/dialer/dialer_overlay.dart';
import 'package:coldcall/features/history/deal_card.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/history_sync/_history_sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _model = di<HistoryVm>();
  static final _timeDateFormat = DateFormat('HH:mm dd.MM.yyyy');

  @override
  void dispose() {
    _model.stopAndDisposeAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        final deals = _model.deals.toList();
        return PopScope(
          canPop: !_model.isDialerShown,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _model.dialerOverlayModel?.closeDialer(false);
          },
          child: Scaffold(
            appBar: AppBar(
              title: (_model.lastSyncStatus.lastSyncTime != null)
                  ? Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        Text('Синхронизировано', style: TextStyle(fontSize: 15)),
                        Text(_timeDateFormat.format(_model.lastSyncStatus.lastSyncTime!), style: TextStyle(fontSize: 14)),
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
                          onRefresh: _model.initFromStorage,
                          child: ListView.builder(
                            itemCount: deals.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              final deal = deals[deals.length - 1 - index];
                              return DealCard(deal: deal);
                            },
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
  }
}

final labelStyle = TextStyle(color: Colors.grey[400], fontSize: 16);
final valueStyle = TextStyle(color: Colors.white, fontSize: 17);

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutesм $secondsс';
}
