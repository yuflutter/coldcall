// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of '_all_syncable_entities.dart';

class DealMapper extends ClassMapperBase<Deal> {
  DealMapper._();

  static DealMapper? _instance;
  static DealMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DealMapper._());
      HistoryRecordMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Deal';

  static int _$id(Deal v) => v.id;
  static const Field<Deal, int> _f$id = Field('id', _$id, opt: true);
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
  static List<HistoryRecord> _$_records(Deal v) => v._records;
  static const Field<Deal, List<HistoryRecord>> _f$_records = Field(
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
  ListCopyWith<
    $R,
    HistoryRecord,
    HistoryRecordCopyWith<$R, HistoryRecord, HistoryRecord>
  >
  get _records;
  $R call({
    int? id,
    DateTime? created,
    String? title,
    List<HistoryRecord>? records,
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
  ListCopyWith<
    $R,
    HistoryRecord,
    HistoryRecordCopyWith<$R, HistoryRecord, HistoryRecord>
  >
  get _records => ListCopyWith(
    $value._records,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(records: v),
  );
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

class HistoryRecordMapper extends ClassMapperBase<HistoryRecord> {
  HistoryRecordMapper._();

  static HistoryRecordMapper? _instance;
  static HistoryRecordMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HistoryRecordMapper._());
      DealMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'HistoryRecord';

  static int _$id(HistoryRecord v) => v.id;
  static const Field<HistoryRecord, int> _f$id = Field('id', _$id, opt: true);
  static Deal? _$deal(HistoryRecord v) => v.deal;
  static const Field<HistoryRecord, Deal> _f$deal = Field(
    'deal',
    _$deal,
    hook: NullMappableFieldHook(),
  );
  static DateTime _$startTime(HistoryRecord v) => v.startTime;
  static const Field<HistoryRecord, DateTime> _f$startTime = Field(
    'startTime',
    _$startTime,
  );
  static Duration _$duration(HistoryRecord v) => v.duration;
  static const Field<HistoryRecord, Duration> _f$duration = Field(
    'duration',
    _$duration,
  );
  static String? _$_phoneNumber(HistoryRecord v) => v._phoneNumber;
  static const Field<HistoryRecord, String> _f$_phoneNumber = Field(
    '_phoneNumber',
    _$_phoneNumber,
    key: r'phoneNumber',
    opt: true,
  );
  static String? _$_audioFileName(HistoryRecord v) => v._audioFileName;
  static const Field<HistoryRecord, String> _f$_audioFileName = Field(
    '_audioFileName',
    _$_audioFileName,
    key: r'audioFileName',
    opt: true,
  );
  static String? _$_textTranscription(HistoryRecord v) => v._textTranscription;
  static const Field<HistoryRecord, String> _f$_textTranscription = Field(
    '_textTranscription',
    _$_textTranscription,
    key: r'textTranscription',
    opt: true,
  );
  static String? _$_note(HistoryRecord v) => v._note;
  static const Field<HistoryRecord, String> _f$_note = Field(
    '_note',
    _$_note,
    key: r'note',
    opt: true,
  );
  static bool _$deleted(HistoryRecord v) => v.deleted;
  static const Field<HistoryRecord, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    opt: true,
  );
  static DateTime _$lastModified(HistoryRecord v) => v.lastModified;
  static const Field<HistoryRecord, DateTime> _f$lastModified = Field(
    'lastModified',
    _$lastModified,
    opt: true,
  );

  @override
  final MappableFields<HistoryRecord> fields = const {
    #id: _f$id,
    #deal: _f$deal,
    #startTime: _f$startTime,
    #duration: _f$duration,
    #_phoneNumber: _f$_phoneNumber,
    #_audioFileName: _f$_audioFileName,
    #_textTranscription: _f$_textTranscription,
    #_note: _f$_note,
    #deleted: _f$deleted,
    #lastModified: _f$lastModified,
  };

  static HistoryRecord _instantiate(DecodingData data) {
    return HistoryRecord(
      id: data.dec(_f$id),
      deal: data.dec(_f$deal),
      startTime: data.dec(_f$startTime),
      duration: data.dec(_f$duration),
      phoneNumber: data.dec(_f$_phoneNumber),
      audioFileName: data.dec(_f$_audioFileName),
      textTranscription: data.dec(_f$_textTranscription),
      note: data.dec(_f$_note),
      deleted: data.dec(_f$deleted),
      lastModified: data.dec(_f$lastModified),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HistoryRecord fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HistoryRecord>(map);
  }

  static HistoryRecord fromJson(String json) {
    return ensureInitialized().decodeJson<HistoryRecord>(json);
  }
}

mixin HistoryRecordMappable {
  String toJson() {
    return HistoryRecordMapper.ensureInitialized().encodeJson<HistoryRecord>(
      this as HistoryRecord,
    );
  }

  Map<String, dynamic> toMap() {
    return HistoryRecordMapper.ensureInitialized().encodeMap<HistoryRecord>(
      this as HistoryRecord,
    );
  }

  HistoryRecordCopyWith<HistoryRecord, HistoryRecord, HistoryRecord>
  get copyWith => _HistoryRecordCopyWithImpl<HistoryRecord, HistoryRecord>(
    this as HistoryRecord,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return HistoryRecordMapper.ensureInitialized().stringifyValue(
      this as HistoryRecord,
    );
  }

  @override
  bool operator ==(Object other) {
    return HistoryRecordMapper.ensureInitialized().equalsValue(
      this as HistoryRecord,
      other,
    );
  }

  @override
  int get hashCode {
    return HistoryRecordMapper.ensureInitialized().hashValue(
      this as HistoryRecord,
    );
  }
}

extension HistoryRecordValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HistoryRecord, $Out> {
  HistoryRecordCopyWith<$R, HistoryRecord, $Out> get $asHistoryRecord =>
      $base.as((v, t, t2) => _HistoryRecordCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HistoryRecordCopyWith<$R, $In extends HistoryRecord, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  DealCopyWith<$R, Deal, Deal>? get deal;
  $R call({
    int? id,
    Deal? deal,
    DateTime? startTime,
    Duration? duration,
    String? phoneNumber,
    String? audioFileName,
    String? textTranscription,
    String? note,
    bool? deleted,
    DateTime? lastModified,
  });
  HistoryRecordCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _HistoryRecordCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HistoryRecord, $Out>
    implements HistoryRecordCopyWith<$R, HistoryRecord, $Out> {
  _HistoryRecordCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HistoryRecord> $mapper =
      HistoryRecordMapper.ensureInitialized();
  @override
  DealCopyWith<$R, Deal, Deal>? get deal =>
      $value.deal?.copyWith.$chain((v) => call(deal: v));
  @override
  $R call({
    Object? id = $none,
    Object? deal = $none,
    DateTime? startTime,
    Duration? duration,
    Object? phoneNumber = $none,
    Object? audioFileName = $none,
    Object? textTranscription = $none,
    Object? note = $none,
    Object? deleted = $none,
    Object? lastModified = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != $none) #id: id,
      if (deal != $none) #deal: deal,
      if (startTime != null) #startTime: startTime,
      if (duration != null) #duration: duration,
      if (phoneNumber != $none) #phoneNumber: phoneNumber,
      if (audioFileName != $none) #audioFileName: audioFileName,
      if (textTranscription != $none) #textTranscription: textTranscription,
      if (note != $none) #note: note,
      if (deleted != $none) #deleted: deleted,
      if (lastModified != $none) #lastModified: lastModified,
    }),
  );
  @override
  HistoryRecord $make(CopyWithData data) => HistoryRecord(
    id: data.get(#id, or: $value.id),
    deal: data.get(#deal, or: $value.deal),
    startTime: data.get(#startTime, or: $value.startTime),
    duration: data.get(#duration, or: $value.duration),
    phoneNumber: data.get(#phoneNumber, or: $value._phoneNumber),
    audioFileName: data.get(#audioFileName, or: $value._audioFileName),
    textTranscription: data.get(
      #textTranscription,
      or: $value._textTranscription,
    ),
    note: data.get(#note, or: $value._note),
    deleted: data.get(#deleted, or: $value.deleted),
    lastModified: data.get(#lastModified, or: $value.lastModified),
  );

  @override
  HistoryRecordCopyWith<$R2, HistoryRecord, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _HistoryRecordCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

