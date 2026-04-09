import 'package:coldcall/core/simple_future_listenable_builders.dart';
import 'package:coldcall/entities/sync_status.dart';
import 'package:coldcall/features/history_sync/_history_sync_vm.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> showHistorySyncScreen(BuildContext context) {
  return Navigator.push(context, MaterialPageRoute(builder: (context) => HistorySyncScreen()));
}

class HistorySyncScreen extends StatefulWidget {
  const HistorySyncScreen({super.key});
  @override
  State<HistorySyncScreen> createState() => _HistorySyncScreenState();
}

class _HistorySyncScreenState extends State<HistorySyncScreen> {
  late final _model = HistorySyncVm();
  late final Future _initFuture = _model.init();

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const vpnMsg = 'ОТКЛЮЧИТЕ VPN на время синхронизации!';
    return SimpleFutureBuilder(
      future: _initFuture,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: _model,
          builder: (context, child) {
            return Scaffold(
              backgroundColor: (_model.status.role == .server && _model.stage == .qrScaning) ? Colors.white : null,
              appBar: AppBar(automaticallyImplyLeading: true, title: Text('Синхронизация')),
              body: (_model.stage == .roleSelecting)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          Spacer(flex: 2),
                          Text(
                            'Выберите на одном телефоне "QR-код", а на втором "Камера".\n\nОба телефона должны находиться в одной WiFi-сети (оба подключены к одному роутеру, либо один телефон в режиме точки доступа, а второй телефон подключен к первому).\n\n$vpnMsg',
                            style: TextStyle(fontSize: 16),
                          ),
                          Spacer(flex: 2),
                          _buildButton(context, onTap: () => _model.setRole(SyncRole.server), actionText: 'QR-код'),
                          Spacer(),
                          _buildButton(context, onTap: () => _model.setRole(SyncRole.client), actionText: 'Камера'),
                          Spacer(flex: 3),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: .fromLTRB(8, 0, 0, 0),
                            child: SelectableText(_model.userLog, style: TextStyle(color: Colors.grey)),
                          ),
                        ),

                        switch (_model.status.role) {
                          .server => switch (_model.stage) {
                            .qrScaning => Column(
                              children: [
                                Spacer(flex: 2),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                                  child: QrImageView(data: _model.qrServerUrl),
                                ),
                                Text(_model.qrServerUrl, style: TextStyle(color: Colors.grey)),
                                Spacer(),
                                Text(vpnMsg, style: TextStyle(color: Colors.black)),
                                Spacer(),
                              ],
                            ),
                            .netConecting => Center(
                              child: Column(
                                mainAxisSize: .min,
                                crossAxisAlignment: .center,
                                children: [
                                  Text('Ожидаю подключения ...'),
                                  Gap(20),
                                  _buildButton(context, onTap: _model.clearConnectionInfo, actionText: 'Сбросить'),
                                ],
                              ),
                            ),
                            _ => _buildSyncStatus(context),
                          },

                          .client => switch (_model.stage) {
                            .qrScaning => SafeArea(
                              child: Stack(
                                children: [
                                  MobileScanner(
                                    // непонятно в каком случае результат сканирования может быть null, поэтому поставил ! в конце
                                    onDetect: (res) => _model.connectAsClient(rawClientUrl: res.barcodes.first.rawValue!),
                                  ),
                                  Positioned(
                                    bottom: MediaQuery.of(context).size.height / 10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Text(vpnMsg, style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            .netConecting => Center(
                              child: Column(
                                // mainAxisSize: .min,
                                crossAxisAlignment: .center,
                                children: [
                                  Spacer(flex: 4),
                                  Text('Попытка подключения к:\n${_model.qrClientUrl} ...'),
                                  Gap(30),
                                  Padding(
                                    padding: .fromLTRB(20, 0, 20, 0),
                                    child: Text(
                                      'Если вы видите это сообщение несколько секунд - значит телефон-клиент не может найти телефон-сервер. Причина может быть в том, что телефоны не подключены к общей WiFi-сети (либо один к другому), либо на одном из них включен VPN.\n\n',
                                    ),
                                  ),
                                  Gap(30),
                                  _buildButton(context, onTap: _model.clearConnectionInfo, actionText: 'Сбросить'),
                                  Spacer(flex: 3),
                                ],
                              ),
                            ),

                            _ => _buildSyncStatus(context),
                          },
                          _ => SizedBox(),
                        },
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    return Center(
      child: switch (_model.stage) {
        .missingFilesSwap => Text('Синхронизация файлов...'),
        .done => _buildButton(context, onTap: () => Navigator.pop(context), actionText: 'Закрыть', infoText: 'Синхронизация завершена'),
        _ => Text('Синхронизация списков...'),
      },
    );
  }

  Widget _buildButton(BuildContext context, {required VoidCallback onTap, required String actionText, String? infoText}) {
    // return SizedBox();
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 100,
        padding: .fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black, // Тот же цвет, что и у контейнера
              blurRadius: 20, // Степень размытия
              spreadRadius: 5, // На сколько пикселей зона расширится наружу
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: .infinity,
            height: 80,
            child: OutlinedButton(
              onPressed: onTap,
              child: Column(
                mainAxisSize: .min,
                children: [
                  if (infoText != null) ...[Text(infoText, style: TextStyle(color: Colors.white70)), Gap(5)],
                  Text(actionText, style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
