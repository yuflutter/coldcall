// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'sync_status.dart';

class SyncRoleMapper extends EnumMapper<SyncRole> {
  SyncRoleMapper._();

  static SyncRoleMapper? _instance;
  static SyncRoleMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SyncRoleMapper._());
    }
    return _instance!;
  }

  static SyncRole fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SyncRole decode(dynamic value) {
    switch (value) {
      case r'notAssigned':
        return SyncRole.notAssigned;
      case r'server':
        return SyncRole.server;
      case r'client':
        return SyncRole.client;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SyncRole self) {
    switch (self) {
      case SyncRole.notAssigned:
        return r'notAssigned';
      case SyncRole.server:
        return r'server';
      case SyncRole.client:
        return r'client';
    }
  }
}

extension SyncRoleMapperExtension on SyncRole {
  String toValue() {
    SyncRoleMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SyncRole>(this) as String;
  }
}

class SyncStatusMapper extends ClassMapperBase<SyncStatus> {
  SyncStatusMapper._();

  static SyncStatusMapper? _instance;
  static SyncStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SyncStatusMapper._());
      SyncRoleMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SyncStatus';

  static DateTime? _$lastSyncTime(SyncStatus v) => v.lastSyncTime;
  static const Field<SyncStatus, DateTime> _f$lastSyncTime = Field(
    'lastSyncTime',
    _$lastSyncTime,
    opt: true,
  );
  static SyncRole _$role(SyncStatus v) => v.role;
  static const Field<SyncStatus, SyncRole> _f$role = Field(
    'role',
    _$role,
    opt: true,
    def: SyncRole.notAssigned,
  );
  static String? _$serverIp(SyncStatus v) => v.serverIp;
  static const Field<SyncStatus, String> _f$serverIp = Field(
    'serverIp',
    _$serverIp,
    opt: true,
  );
  static String? _$clientUrl(SyncStatus v) => v.clientUrl;
  static const Field<SyncStatus, String> _f$clientUrl = Field(
    'clientUrl',
    _$clientUrl,
    opt: true,
  );

  @override
  final MappableFields<SyncStatus> fields = const {
    #lastSyncTime: _f$lastSyncTime,
    #role: _f$role,
    #serverIp: _f$serverIp,
    #clientUrl: _f$clientUrl,
  };

  static SyncStatus _instantiate(DecodingData data) {
    return SyncStatus(
      lastSyncTime: data.dec(_f$lastSyncTime),
      role: data.dec(_f$role),
      serverIp: data.dec(_f$serverIp),
      clientUrl: data.dec(_f$clientUrl),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SyncStatus fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SyncStatus>(map);
  }

  static SyncStatus fromJson(String json) {
    return ensureInitialized().decodeJson<SyncStatus>(json);
  }
}

mixin SyncStatusMappable {
  String toJson() {
    return SyncStatusMapper.ensureInitialized().encodeJson<SyncStatus>(
      this as SyncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return SyncStatusMapper.ensureInitialized().encodeMap<SyncStatus>(
      this as SyncStatus,
    );
  }

  SyncStatusCopyWith<SyncStatus, SyncStatus, SyncStatus> get copyWith =>
      _SyncStatusCopyWithImpl<SyncStatus, SyncStatus>(
        this as SyncStatus,
        $identity,
        $identity,
      );
}

extension SyncStatusValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SyncStatus, $Out> {
  SyncStatusCopyWith<$R, SyncStatus, $Out> get $asSyncStatus =>
      $base.as((v, t, t2) => _SyncStatusCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SyncStatusCopyWith<$R, $In extends SyncStatus, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    DateTime? lastSyncTime,
    SyncRole? role,
    String? serverIp,
    String? clientUrl,
  });
  SyncStatusCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SyncStatusCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SyncStatus, $Out>
    implements SyncStatusCopyWith<$R, SyncStatus, $Out> {
  _SyncStatusCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SyncStatus> $mapper =
      SyncStatusMapper.ensureInitialized();
  @override
  $R call({
    Object? lastSyncTime = $none,
    SyncRole? role,
    Object? serverIp = $none,
    Object? clientUrl = $none,
  }) => $apply(
    FieldCopyWithData({
      if (lastSyncTime != $none) #lastSyncTime: lastSyncTime,
      if (role != null) #role: role,
      if (serverIp != $none) #serverIp: serverIp,
      if (clientUrl != $none) #clientUrl: clientUrl,
    }),
  );
  @override
  SyncStatus $make(CopyWithData data) => SyncStatus(
    lastSyncTime: data.get(#lastSyncTime, or: $value.lastSyncTime),
    role: data.get(#role, or: $value.role),
    serverIp: data.get(#serverIp, or: $value.serverIp),
    clientUrl: data.get(#clientUrl, or: $value.clientUrl),
  );

  @override
  SyncStatusCopyWith<$R2, SyncStatus, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SyncStatusCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

