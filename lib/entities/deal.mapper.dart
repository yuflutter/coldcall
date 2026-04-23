// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deal.dart';

class DealMapper extends ClassMapperBase<Deal> {
  DealMapper._();

  static DealMapper? _instance;
  static DealMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DealMapper._());
      SyncableListMapper.ensureInitialized();
      HistoryRecordMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Deal';

  static String _$id(Deal v) => v.id;
  static const Field<Deal, String> _f$id = Field('id', _$id, opt: true);
  static DateTime _$created(Deal v) => v.created;
  static const Field<Deal, DateTime> _f$created = Field(
    'created',
    _$created,
    opt: true,
  );
  static String _$_title(Deal v) => v._title;
  static const Field<Deal, String> _f$_title = Field(
    '_title',
    _$_title,
    key: r'title',
  );
  static SyncableList<HistoryRecord> _$_records(Deal v) => v._records;
  static const Field<Deal, SyncableList<HistoryRecord>> _f$_records = Field(
    '_records',
    _$_records,
    key: r'records',
    opt: true,
  );
  static bool _$deleted(Deal v) => v.deleted;
  static const Field<Deal, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    opt: true,
  );
  static DateTime _$lastModified(Deal v) => v.lastModified;
  static const Field<Deal, DateTime> _f$lastModified = Field(
    'lastModified',
    _$lastModified,
    opt: true,
  );

  @override
  final MappableFields<Deal> fields = const {
    #id: _f$id,
    #created: _f$created,
    #_title: _f$_title,
    #_records: _f$_records,
    #deleted: _f$deleted,
    #lastModified: _f$lastModified,
  };

  static Deal _instantiate(DecodingData data) {
    return Deal(
      id: data.dec(_f$id),
      created: data.dec(_f$created),
      title: data.dec(_f$_title),
      records: data.dec(_f$_records),
      deleted: data.dec(_f$deleted),
      lastModified: data.dec(_f$lastModified),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Deal fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Deal>(map);
  }

  static Deal fromJson(String json) {
    return ensureInitialized().decodeJson<Deal>(json);
  }
}

mixin DealMappable {
  String toJson() {
    return DealMapper.ensureInitialized().encodeJson<Deal>(this as Deal);
  }

  Map<String, dynamic> toMap() {
    return DealMapper.ensureInitialized().encodeMap<Deal>(this as Deal);
  }

  DealCopyWith<Deal, Deal, Deal> get copyWith =>
      _DealCopyWithImpl<Deal, Deal>(this as Deal, $identity, $identity);
  @override
  String toString() {
    return DealMapper.ensureInitialized().stringifyValue(this as Deal);
  }

  @override
  bool operator ==(Object other) {
    return DealMapper.ensureInitialized().equalsValue(this as Deal, other);
  }

  @override
  int get hashCode {
    return DealMapper.ensureInitialized().hashValue(this as Deal);
  }
}

extension DealValueCopy<$R, $Out> on ObjectCopyWith<$R, Deal, $Out> {
  DealCopyWith<$R, Deal, $Out> get $asDeal =>
      $base.as((v, t, t2) => _DealCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DealCopyWith<$R, $In extends Deal, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  SyncableListCopyWith<
    $R,
    SyncableList<HistoryRecord>,
    SyncableList<HistoryRecord>,
    HistoryRecord
  >
  get _records;
  $R call({
    String? id,
    DateTime? created,
    String? title,
    SyncableList<HistoryRecord>? records,
    bool? deleted,
    DateTime? lastModified,
  });
  DealCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DealCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Deal, $Out>
    implements DealCopyWith<$R, Deal, $Out> {
  _DealCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Deal> $mapper = DealMapper.ensureInitialized();
  @override
  SyncableListCopyWith<
    $R,
    SyncableList<HistoryRecord>,
    SyncableList<HistoryRecord>,
    HistoryRecord
  >

get _records => (($value._records as SyncableList<HistoryRecord>).copyWith
    .$chain((v) => call(records: v))) as SyncableListCopyWith<$R, SyncableList<HistoryRecord>, SyncableList<HistoryRecord>, HistoryRecord>;

  @override
  $R call({
    Object? id = $none,
    Object? created = $none,
    String? title,
    Object? records = $none,
    Object? deleted = $none,
    Object? lastModified = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != $none) #id: id,
      if (created != $none) #created: created,
      if (title != null) #title: title,
      if (records != $none) #records: records,
      if (deleted != $none) #deleted: deleted,
      if (lastModified != $none) #lastModified: lastModified,
    }),
  );
  @override
  Deal $make(CopyWithData data) => Deal(
    id: data.get(#id, or: $value.id),
    created: data.get(#created, or: $value.created),
    title: data.get(#title, or: $value._title),
    records: data.get(#records, or: $value._records),
    deleted: data.get(#deleted, or: $value.deleted),
    lastModified: data.get(#lastModified, or: $value.lastModified),
  );

  @override
  DealCopyWith<$R2, Deal, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DealCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

