import 'package:dart_mappable/dart_mappable.dart';

part 'sync_status.mapper.dart';

@MappableEnum()
enum SyncRole { notAssigned, server, client }

@MappableClass()
class SyncStatus with SyncStatusMappable {
  final DateTime? lastSyncTime;
  final SyncRole role;
  final String? serverIp;
  final String? clientUrl;

  const SyncStatus({this.lastSyncTime, this.role = SyncRole.notAssigned, this.serverIp, this.clientUrl});
}
