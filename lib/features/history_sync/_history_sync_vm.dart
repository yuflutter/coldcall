import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/log.dart';
import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/storage_bundle.dart';
import 'package:coldcall/entities/sync_status.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Вообще тут нужен конечный автомат на классах, но я поленился. Прошу понять и простить.
enum SyncStage { roleSelecting, qrScaning, netConecting, lastSyncTimeSwap, jsonSwap, missingFileNamesSwap, missingFilesSwap, done }

class HistorySyncVm with SimpleChangeNotifier {
  static const _qrUrlPrefix = 'coldcall:';

  late SyncStatus status;
  var stage = SyncStage.roleSelecting;

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

    status = di<Storage>().lastSyncStatus;

    // Если инфа о синхронизации сохранена в статусе - пропускаем стадии выбора роли и сканирования QR
    switch (status.role) {
      case .server:
        notify(() => stage = .netConecting);
        startAsServer();

      case .client:
        notify(() => stage = .netConecting);
        connectAsClient();

      default:
    }
  }

  void setRole(final SyncRole role) async {
    notify(() {
      status = status.copyWith(role: role);
      stage = .qrScaning;
    });

    if (role == .server) startAsServer();
  }

  void clearConnectionInfo() {
    notify(() {
      status = status.copyWith(role: .notAssigned, serverIp: null, clientUrl: null);
      stage = SyncStage.roleSelecting;
      _userLog.clear();
    });
    _socket?.close();
    _server?.close();
    _channel?.sink.close();
  }

  Future<void> startAsServer() async {
    try {
      String? serverIp;
      serverIp = await NetworkInfo().getWifiIP();
      if (serverIp == null) throw 'Can\'t determine my IP';

      notify(() => status = status.copyWith(serverIp: serverIp));

      _server = await HttpServer.bind(InternetAddress.anyIPv4, di<AppConfig>().historySyncHttpPort);
      _log.inf('Listening on ${status.serverIp}:${di<AppConfig>().historySyncHttpPort} ...');

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

  Future<void> connectAsClient({final String? rawClientUrl}) async {
    if (rawClientUrl != null && !rawClientUrl.startsWith(_qrUrlPrefix)) {
      throw 'Incorrect client URL: $rawClientUrl';
    } else if (rawClientUrl != null) {
      notify(() => status = status.copyWith(clientUrl: rawClientUrl.replaceFirst(_qrUrlPrefix, '')));
    }

    notify(() => stage = .netConecting);

    while (status.clientUrl != null) {
      try {
        _channel = WebSocketChannel.connect(Uri.parse(status.clientUrl!));
        await _channel!.ready;
        _log.inf('Connected to ${status.clientUrl}');

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
        return;
        //
      } catch (e) {
        notify(() => _userLog.writeln(e.toString()));
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> reconnectAsClient() => connectAsClient(rawClientUrl: status.clientUrl);

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

          _wsSend(di<Storage>().getNotSyncedBundle(remotLastSyncTime).toJson());

        // принимаем json, отправляем список имен фойлов, в ответ ожидаем того же
        case .jsonSwap:
          final remoteBundle = StorageBundleMapper.fromJson(incoming);
          notify(() => stage = .missingFileNamesSwap);

          _missingFileNames = await _processIncomingJson(remoteBundle);
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

  // Принимаем пакет измененных данных, делаем merge адресной книги, дел, и записей истории
  Future<List<String>> _processIncomingJson(StorageBundle remoteBundle) async {
    final storage = di<Storage>();

    // синхронизируем телефонную книгу
    for (final remotePhoneNumber in remoteBundle.phoneBook) {
      storage.mergeAndSavePhoneNumber(remotePhoneNumber);
    }

    // формируем список имен файлов, ссылки на которые есть, а самих файлов нет
    final missingFileNames = <String>[];
    for (final remoteDeal in remoteBundle.deals) {
      if (!remoteDeal.deleted) {
        for (final remoteRecord in remoteDeal.records) {
          if (remoteRecord.audioFileName != null) {
            if (!File(await remoteRecord.audioFilePath()!).existsSync()) {
              missingFileNames.add(remoteRecord.audioFileName!);
            }
          }
        }
      }

      // синхронизируем дело (включая записи истории)
      storage.mergeAndSaveDeal(remoteDeal);
    }

    await storage.saveAllToStorage();
    storage.notifyListeners();

    return missingFileNames;
  }

  Future<void> _done() async {
    try {
      final storage = di<Storage>();
      await storage.updateLastSyncStatus(status.copyWith(lastSyncTime: DateTime.now()));
      await storage.saveAllToStorage();
      di<HistoryVm>().refreshAll();
      notify(() => stage = .done);
    } catch (e, s) {
      Err.add(e, s);
    }
  }
}
