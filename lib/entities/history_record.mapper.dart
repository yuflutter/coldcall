// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'history_record.dart';

class HistoryRecordMapper extends ClassMapperBase<HistoryRecord> {
  HistoryRecordMapper._();

  static HistoryRecordMapper? _instance;
  static HistoryRecordMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HistoryRecordMapper._());
      DealMapper.ensureInitialized();
      PhoneNumberMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'HistoryRecord';

  static String _$id(HistoryRecord v) => v.id;
  static const Field<HistoryRecord, String> _f$id = Field('id', _$id);
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
  static PhoneNumber? _$_phoneNumber(HistoryRecord v) => v._phoneNumber;
  static const Field<HistoryRecord, PhoneNumber> _f$_phoneNumber = Field(
    '_phoneNumber',
    _$_phoneNumber,
    key: r'phoneNumber',
    opt: true,
    hook: NullMappableFieldHook(),
  );
  static String? _$_phoneNumberId(HistoryRecord v) => v._phoneNumberId;
  static const Field<HistoryRecord, String> _f$_phoneNumberId = Field(
    '_phoneNumberId',
    _$_phoneNumberId,
    key: r'phoneNumberId',
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
    #_phoneNumberId: _f$_phoneNumberId,
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
      phoneNumberId: data.dec(_f$_phoneNumberId),
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
  PhoneNumberCopyWith<$R, PhoneNumber, PhoneNumber>? get _phoneNumber;
  $R call({
    String? id,
    Deal? deal,
    DateTime? startTime,
    Duration? duration,
    PhoneNumber? phoneNumber,
    String? phoneNumberId,
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
  PhoneNumberCopyWith<$R, PhoneNumber, PhoneNumber>? get _phoneNumber =>
      $value._phoneNumber?.copyWith.$chain((v) => call(phoneNumber: v));
  @override
  $R call({
    Object? id = $none,
    Object? deal = $none,
    DateTime? startTime,
    Duration? duration,
    Object? phoneNumber = $none,
    Object? phoneNumberId = $none,
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
      if (phoneNumberId != $none) #phoneNumberId: phoneNumberId,
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
    phoneNumberId: data.get(#phoneNumberId, or: $value._phoneNumberId),
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

