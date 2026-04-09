import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/_all_syncable_entities.dart';
import 'package:coldcall/entities/sync_status.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Вообще тут нужен конечный автомат на классах, но я поленился. Прошу понять и простить.
enum SyncStage { roleSelecting, qrScaning, netConecting, lastSyncTimeSwap, jsonSwap, missingFileNamesSwap, missingFilesSwap, done }

class HistorySyncVm with SimpleChangeNotifier {
  static const _qrUrlPrefix = 'coldcall:';

  late SyncStatus status;
  var stage = SyncStage.roleSelecting;

  Future<void>? startFuture;

  final _userLog = StringBuffer();
  String get userLog => _userLog.toString();
  late final _log = Log('$runtimeType', on: (m) => notify(() => _userLog.writeln(m)));

  String get qrServerUrl => '${_qrUrlPrefix}ws://${status.serverIp}:${di<AppConfig>().historySyncHttpPort}';
  HttpServer? _server;
  WebSocket? _socket;

  String get qrClientUrl => '${status.clientUrl}';
  WebSocketChannel? _channel;

  void Function(dynamic)? _wsSender;

  late final String _localFilePath;
  List<String>? _missingFileNames;

  @override
  void dispose() {
    _socket?.close();
    _server?.close();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> init() async {
    _localFilePath = (await getApplicationDocumentsDirectory()).path;

    status = di<HistoryVm>().lastSyncStatus;

    // TODO: Фоновая синхронизация сейчас не работает, продумать куда выводить ошибки и лог

    if (status.role != .notAssigned) {
      notify(() {
        startFuture = (status.role == .server) ? startAsServer() : connectAsClient(clientUrl: status.clientUrl);
        stage = .netConecting;
      });
    }
  }

  void reconnectAsClient() => connectAsClient(clientUrl: status.clientUrl);

  void clearConnectionInfo() {
    notify(() {
      status = status.copyWith(role: .notAssigned, serverIp: null, clientUrl: null);
      stage = SyncStage.roleSelecting;
    });
  }

  void setRole(final SyncRole role) async {
    String? serverIp;
    if (role == .server) {
      serverIp = await NetworkInfo().getWifiIP();
      _log.war(serverIp);
      if (serverIp == null) throw 'Не могу определить свой IP';
    }
    notify(() {
      status = status.copyWith(role: role, serverIp: serverIp);
      startFuture = (role == .server) ? startAsServer() : Future.value(null);
      stage = .qrScaning;
    });
  }

  Future<void> startAsServer() async {
    final serverIp = await NetworkInfo().getWifiIP();
    if (serverIp == null) throw 'Не могу определить свой IP';

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, di<AppConfig>().historySyncHttpPort);
      _log.inf('Listening on $serverIp:${di<AppConfig>().historySyncHttpPort} ...');

      _server!.listen((request) async {
        notify(() => stage = .netConecting);
        try {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            _socket = await WebSocketTransformer.upgrade(request);
            _log.inf('Connect received from: ${request.connectionInfo?.remoteAddress.address}');

            _wsSender = _socket!.add;
            _sendLastSyncTime();

            await for (final data in _socket!) {
              await _handleIncoming(data);
            }
            //
          } else {
            request.response
              ..statusCode = HttpStatus.forbidden
              ..close();
            throw 'WebSocketTransformer.upgrade failed';
          }
        } catch (e, s) {
          Err.add(e, s);
        }
      });
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<void> connectAsClient({required final String? clientUrl}) async {
    if (clientUrl == null || !clientUrl.startsWith(_qrUrlPrefix)) return;

    notify(() {
      status = status.copyWith(clientUrl: clientUrl);
      stage = .netConecting;
    });

    try {
      final url = clientUrl.replaceFirst(_qrUrlPrefix, '');

      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _log.inf('Connected to $url');

      _wsSender = _channel!.sink.add;
      _sendLastSyncTime();

      // Завершаем connectAsClient, так как она используется в FutureBuilder
      () async {
        try {
          await for (final data in _channel!.stream) {
            await _handleIncoming(data);
          }
        } catch (e, s) {
          Err.add(e, s);
        }
      }();
      //
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  // первое сообщение в сокет - отправляем время последней синхронизации, в ответ ожидаем того же
  void _sendLastSyncTime() {
    notify(() => stage = .lastSyncTimeSwap);
    _wsSend(jsonEncode(status.lastSyncTime?.millisecondsSinceEpoch ?? 0));
  }

  void _wsSend(dynamic data) {
    final msg = '>>>  ${stage.name} =  ' + ((data is Uint8List) ? 'binary data [${data.length}]' : data);
    _log.inf(msg);
    _wsSender!(data);
  }

  // Вообще тут нужен конечный автомат на классах, но я поленился, и использую упрощенный подход -
  // ручное формирование/парсинг json-сообщений, управляемый енамом. Прошу понять и простить.
  Future<void> _handleIncoming(dynamic incoming) async {
    _log.inf('<<<  ' + ((incoming is Uint8List) ? 'binary data [${incoming.length}]' : incoming));
    try {
      switch (stage) {
        // принимаем время, отправляем json, в ответ ожидаем того же
        case .lastSyncTimeSwap:
          final remotLastSyncTime = DateTime.fromMillisecondsSinceEpoch(jsonDecode(incoming));
          notify(() => stage = .jsonSwap);

          _wsSend(jsonEncode(di<HistoryVm>().notSyncedDeals(remotLastSyncTime).toList()));

        // принимаем json, отправляем список имен фойлов, в ответ ожидаем того же
        case .jsonSwap:
          final deals = (jsonDecode(incoming) as List).map((e) => DealMapper.fromJson(e)).toList();
          notify(() => stage = .missingFileNamesSwap);

          _missingFileNames = await _processIncomingJson(deals);
          _wsSend(jsonEncode(_missingFileNames));

        // принимаем список путей к файлам, отправляем сами файлы, в ответ ожидаем того же
        case .missingFileNamesSwap:
          final missingFileNames = (jsonDecode(incoming) as List).map((e) => e as String).toList();
          notify(() => stage = .missingFilesSwap);

          for (final fileName in missingFileNames) {
            final file = File('$_localFilePath/$fileName');
            if (file.existsSync()) {
              _wsSend(await file.readAsBytes());
            } else {
              throw 'File "$fileName" is not found';
            }
          }
          _wsSend(jsonEncode(true));

        // принимаем файлы, когда принят последний - завершаем сеанс
        // TODO: Довольно хлипкий алгоритм - ожидаем поступления файлов в порядке запрошенных ранее имен... а если ошибка... в общем, исправить когда деньги заплатят ))
        case .missingFilesSwap:
          if (incoming is Uint8List) {
            if (_missingFileNames!.isNotEmpty) {
              final fileName = _missingFileNames!.removeAt(0);
              final file = File('$_localFilePath/$fileName');
              await file.writeAsBytes(incoming);
            } else {
              throw 'Получен лишний файл';
            }
          } else {
            if (jsonDecode(incoming) == true) await _done();
          }

        default:
          _log.war(incoming);
      }
    } catch (e, s) {
      Err.add(e, s);
    }
  }

  Future<List<String>> _processIncomingJson(List<Deal> remoteDeals) async {
    final history = di<HistoryVm>();
    final missingFileNames = <String>[];

    for (final remoteDeal in remoteDeals) {
      // формируем список имен файлов, ссылки на которые есть, а самих файлов нет
      if (!remoteDeal.deleted) {
        for (final remoteRecord in remoteDeal.records) {
          if (remoteRecord.audioFileName != null) {
            if (!File(await remoteRecord.audioFilePath()!).existsSync()) {
              missingFileNames.add(remoteRecord.audioFileName!);
            }
          }
        }
      }

      history.mergeDeal(remoteDeal);
    }
    await history.saveToStorage();
    history.notifyListeners();

    return missingFileNames;
  }

  Future<void> _done() async {
    try {
      final history = di<HistoryVm>();
      await history.updateLastSyncStatus(status.copyWith(lastSyncTime: DateTime.now()));
      await history.saveToStorage();
      notify(() => stage = .done);
    } catch (e, s) {
      Err.add(e, s);
    }
  }
}
