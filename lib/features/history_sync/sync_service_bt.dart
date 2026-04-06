// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:coldcall/core/di.dart';
// import 'package:coldcall/core/err.dart';
// import 'package:coldcall/entities/_all_syncable_entities.dart';
// import 'package:coldcall/features/history/_history_vm.dart';
// import 'package:flutter/foundation.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// /// Двухэтапная Bluetooth-синхронизация истории сделок между двумя устройствами.
// ///
// /// Этап 1 — метаданные:
// ///   Оба устройства отправляют JSON своих notSyncedDeals.
// ///   Получив данные партнёра, выполняем merge в HistoryVm.
// ///
// /// Этап 2 — аудиофайлы:
// ///   После merge определяем, каких файлов не хватает локально.
// ///   Запрашиваем их у партнёра; партнёр отвечает отправкой файлов.
// ///   По завершении обновляем lastSyncTime.
// ///
// /// Использование:
// ///   DI.put(SyncService());
// ///   // Одно устройство:
// ///   di<SyncService>().startAdvertising();
// ///   // Другое устройство:
// ///   di<SyncService>().startDiscovery();

// class SyncService with ChangeNotifier {
//   static const _serviceId = 'com.example.coldcall.sync';
//   static const _deviceName = 'ColdCallDevice';

//   final _nearby = Nearby();

//   String? _connectedEndpointId;
//   bool get isConnected => _connectedEndpointId != null;

//   SyncStatus status = SyncStatus.idle;
//   String? lastError;

//   // recordId -> ожидаемое имя файла (заполняется после merge)
//   final _pendingFilesByRecordId = <int, String>{};
//   // payloadId -> recordId (заполняется при получении FILE payload)
//   final _inFlightFiles = <int, int>{};

//   // Буфер для сборки JSON из нескольких BYTES-чанков
//   final _bytesBuffer = <String, StringBuffer>{};

//   Completer<void>? _metaReceived;
//   Completer<void>? _filesReceived;

//   // -----------------------------------------------------------------------
//   // Публичный API
//   // -----------------------------------------------------------------------

//   Future<void> startAdvertising() async {
//     if (!(await _requestPermission())) return;

//     _setStatus(SyncStatus.advertising);
//     try {
//       await _nearby.startAdvertising(
//         _deviceName,
//         Strategy.P2P_POINT_TO_POINT,
//         onConnectionInitiated: _onConnectionInitiated,
//         onConnectionResult: _onConnectionResult,
//         onDisconnected: _onDisconnected,
//         serviceId: _serviceId,
//       );
//     } catch (e, s) {
//       Err.add(e, s);
//       _setStatus(SyncStatus.error, error: e.toString());
//     }
//   }

//   Future<void> stopAdvertising() async {
//     await _nearby.stopAdvertising();
//     if (status == SyncStatus.advertising) _setStatus(SyncStatus.idle);
//   }

//   Future<void> startDiscovery() async {
//     if (!(await _requestPermission())) return;

//     _setStatus(SyncStatus.discovering);
//     try {
//       await _nearby.startDiscovery(
//         _deviceName,
//         Strategy.P2P_POINT_TO_POINT,
//         onEndpointFound: (id, name, serviceId) async {
//           await _nearby.stopDiscovery();
//           await _nearby.requestConnection(
//             _deviceName,
//             id,
//             onConnectionInitiated: _onConnectionInitiated,
//             onConnectionResult: _onConnectionResult,
//             onDisconnected: _onDisconnected,
//           );
//         },
//         onEndpointLost: (_) {},
//         serviceId: _serviceId,
//       );
//     } catch (e, s) {
//       Err.add(e, s);
//       _setStatus(SyncStatus.error, error: e.toString());
//     }
//   }

//   Future<void> stopDiscovery() async {
//     await _nearby.stopDiscovery();
//     if (status == SyncStatus.discovering) _setStatus(SyncStatus.idle);
//   }

//   Future<void> disconnect() async {
//     if (_connectedEndpointId != null) {
//       await _nearby.disconnectFromEndpoint(_connectedEndpointId!);
//     }
//     await _nearby.stopAllEndpoints();
//     _connectedEndpointId = null;
//   }

//   Future<bool> _requestPermission() async {
//     // if (Platform.isAndroid) {
//     // final androidInfo = await DeviceInfoPlugin().androidInfo;

//     // if (androidInfo.version.sdkInt >= 33) {
//     //   // Для Android 13+ запрашиваем специальное разрешение Wi-Fi
//     //   await Permission.nearbyWifiDevices.request();
//     // } else {
//     //   // Для Android 12 и ниже всё еще требуется местоположение
//     //   await Permission.location.request();
//     // }

//     final res = await [
//       Permission.nearbyWifiDevices,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//     ].request();
//     return !res.values.any((e) => e.isDenied);
//   }

//   // -----------------------------------------------------------------------
//   // Обработка подключения
//   // -----------------------------------------------------------------------

//   void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
//     _nearby.acceptConnection(endpointId, onPayLoadRecieved: _onPayloadReceived, onPayloadTransferUpdate: _onPayloadTransferUpdate);
//   }

//   void _onConnectionResult(String endpointId, Status result) {
//     if (result == Status.CONNECTED) {
//       _connectedEndpointId = endpointId;
//       _setStatus(SyncStatus.connected);
//       _runSync();
//     } else {
//       _setStatus(SyncStatus.error, error: 'Connection failed: $result');
//     }
//   }

//   void _onDisconnected(String endpointId) {
//     _connectedEndpointId = null;
//     if (status != SyncStatus.done) _setStatus(SyncStatus.idle);
//   }

//   // -----------------------------------------------------------------------
//   // Основной поток синхронизации
//   // -----------------------------------------------------------------------

//   Future<void> _runSync() async {
//     try {
//       await _phase1Meta();
//       await _phase2Files();
//       await _finish();
//     } catch (e, s) {
//       Err.add(e, s);
//       _setStatus(SyncStatus.error, error: e.toString());
//     }
//   }

//   // -----------------------------------------------------------------------
//   // Этап 1: метаданные
//   // -----------------------------------------------------------------------

//   Future<void> _phase1Meta() async {
//     _setStatus(SyncStatus.syncingMeta);
//     _metaReceived = Completer<void>();

//     final history = di<HistoryVm>();
//     final payload = _encodeMsg({'type': 'meta', 'deals': history.notSyncedDeals.map((d) => d.toJson()).toList()});
//     await _sendBytes(payload);

//     // Ждём, пока партнёр пришлёт свои метаданные (обработка в _onBytesMessage)
//     await _metaReceived!.future.timeout(const Duration(seconds: 60));
//   }

//   Future<void> _handleMetaMessage(Map<String, dynamic> msg) async {
//     final history = di<HistoryVm>();
//     final remoteDeals = (msg['deals'] as List).map((e) => DealMapper.fromJson(e)).toList();

//     // merge возвращает id записей, у которых нет аудиофайла локально
//     final missingIds = await history.mergeRemoteDeals(remoteDeals);

//     // Сохраняем ожидаемые имена файлов (будем сопоставлять по recordId)
//     for (final id in missingIds) {
//       _pendingFilesByRecordId[id] = _audioFileName(id);
//     }

//     _metaReceived?.complete();
//   }

//   // -----------------------------------------------------------------------
//   // Этап 2: аудиофайлы
//   // -----------------------------------------------------------------------

//   Future<void> _phase2Files() async {
//     _setStatus(SyncStatus.syncingFiles);

//     if (_pendingFilesByRecordId.isEmpty) return; // нечего запрашивать

//     _filesReceived = Completer<void>();

//     // Запрашиваем у партнёра нужные файлы
//     await _sendBytes(_encodeMsg({'type': 'file_request', 'recordIds': _pendingFilesByRecordId.keys.toList()}));

//     // Ждём получения всех файлов
//     await _filesReceived!.future.timeout(const Duration(minutes: 5));
//   }

//   Future<void> _handleFileRequestMessage(Map<String, dynamic> msg) async {
//     final history = di<HistoryVm>();
//     final recordIds = (msg['recordIds'] as List).cast<int>();

//     for (final recordId in recordIds) {
//       // Ищем запись с нужным аудиофайлом
//       String? filePath;
//       outer:
//       for (final deal in history.deals) {
//         for (final record in deal.records) {
//           if (record.id == recordId && record.audioFilePath != null) {
//             filePath = record.audioFilePath;
//             break outer;
//           }
//         }
//       }

//       if (filePath == null) continue;
//       final file = File(filePath);
//       if (!await file.exists()) continue;

//       // Отправляем файл; payloadId используем как маркер recordId
//       await _nearby.sendFilePayload(_connectedEndpointId!, filePath);
//     }
//   }

//   Future<void> _handleFileReceived(int payloadId, String savedPath) async {
//     final recordId = _inFlightFiles.remove(payloadId);
//     if (recordId == null) return;

//     _pendingFilesByRecordId.remove(recordId);

//     await di<HistoryVm>().setAudioFileForRecord(recordId, savedPath);

//     if (_pendingFilesByRecordId.isEmpty) {
//       _filesReceived?.complete();
//     }
//   }

//   // -----------------------------------------------------------------------
//   // Завершение
//   // -----------------------------------------------------------------------

//   Future<void> _finish() async {
//     await di<HistoryVm>().updateLastSyncTime();
//     _setStatus(SyncStatus.done);
//     await disconnect();
//   }

//   // -----------------------------------------------------------------------
//   // Входящие payload
//   // -----------------------------------------------------------------------

//   void _onPayloadReceived(String endpointId, Payload payload) async {
//     try {
//       switch (payload.type) {
//         case PayloadType.BYTES:
//           _accumulateBytes(endpointId, payload.bytes!);
//         case PayloadType.FILE:
//           // Файл сохраняется nearby_connections в кэш; recordId сопоставим в onPayloadTransferUpdate
//           _inFlightFiles[payload.id] = payload.id;
//         default:
//           break;
//       }
//     } catch (e, s) {
//       Err.add(e, s);
//     }
//   }

//   void _onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) async {
//     if (update.status == PayloadStatus.SUCCESS) {
//       final recordId = _inFlightFiles[update.id];
//       if (recordId != null) {
//         // Файл получен полностью — nearby_connections сохраняет его в Downloads или кэш
//         // Путь к файлу нужно получить из payload; здесь используем заранее известное имя
//         final dir = await getApplicationDocumentsDirectory();
//         final destPath = '${dir.path}/${update.id}.m4a';
//         await _handleFileReceived(update.id, destPath);
//       }
//     }
//     notifyListeners();
//   }

//   // -----------------------------------------------------------------------
//   // Буферизация и парсинг BYTES
//   // -----------------------------------------------------------------------

//   void _accumulateBytes(String endpointId, Uint8List bytes) {
//     final buf = _bytesBuffer.putIfAbsent(endpointId, () => StringBuffer());
//     buf.write(utf8.decode(bytes));

//     // Пробуем распарсить накопленный JSON
//     try {
//       final map = jsonDecode(buf.toString()) as Map<String, dynamic>;
//       _bytesBuffer.remove(endpointId); // успешно — очищаем буфер
//       _onBytesMessage(map);
//     } catch (_) {
//       // JSON ещё неполный — ждём следующего чанка
//     }
//   }

//   void _onBytesMessage(Map<String, dynamic> msg) async {
//     switch (msg['type'] as String) {
//       case 'meta':
//         await _handleMetaMessage(msg);
//       case 'file_request':
//         await _handleFileRequestMessage(msg);
//     }
//   }

//   // -----------------------------------------------------------------------
//   // Утилиты
//   // -----------------------------------------------------------------------

//   Future<void> _sendBytes(Uint8List bytes) async {
//     if (_connectedEndpointId == null) throw StateError('Not connected');
//     await _nearby.sendBytesPayload(_connectedEndpointId!, bytes);
//   }

//   Uint8List _encodeMsg(Map<String, dynamic> msg) => Uint8List.fromList(utf8.encode(jsonEncode(msg)));

//   String _audioFileName(int recordId) => 'audio_$recordId.m4a';

//   void _setStatus(SyncStatus s, {String? error}) {
//     status = s;
//     lastError = error;
//     notifyListeners();
//   }
// }

// enum SyncStatus { idle, advertising, discovering, connected, syncingMeta, syncingFiles, done, error }
