// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'user_settings.dart';

class UserSettingsMapper extends ClassMapperBase<UserSettings> {
  UserSettingsMapper._();

  static UserSettingsMapper? _instance;
  static UserSettingsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = UserSettingsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'UserSettings';

  static bool _$isRecordingEnabled(UserSettings v) => v.isRecordingEnabled;
  static const Field<UserSettings, bool> _f$isRecordingEnabled = Field(
    'isRecordingEnabled',
    _$isRecordingEnabled,
  );
  static bool _$isTranscriptionEnabled(UserSettings v) =>
      v.isTranscriptionEnabled;
  static const Field<UserSettings, bool> _f$isTranscriptionEnabled = Field(
    'isTranscriptionEnabled',
    _$isTranscriptionEnabled,
  );

  @override
  final MappableFields<UserSettings> fields = const {
    #isRecordingEnabled: _f$isRecordingEnabled,
    #isTranscriptionEnabled: _f$isTranscriptionEnabled,
  };

  static UserSettings _instantiate(DecodingData data) {
    return UserSettings(
      isRecordingEnabled: data.dec(_f$isRecordingEnabled),
      isTranscriptionEnabled: data.dec(_f$isTranscriptionEnabled),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static UserSettings fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<UserSettings>(map);
  }

  static UserSettings fromJson(String json) {
    return ensureInitialized().decodeJson<UserSettings>(json);
  }
}

mixin UserSettingsMappable {
  String toJson() {
    return UserSettingsMapper.ensureInitialized().encodeJson<UserSettings>(
      this as UserSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return UserSettingsMapper.ensureInitialized().encodeMap<UserSettings>(
      this as UserSettings,
    );
  }

  UserSettingsCopyWith<UserSettings, UserSettings, UserSettings> get copyWith =>
      _UserSettingsCopyWithImpl<UserSettings, UserSettings>(
        this as UserSettings,
        $identity,
        $identity,
      );
}

extension UserSettingsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, UserSettings, $Out> {
  UserSettingsCopyWith<$R, UserSettings, $Out> get $asUserSettings =>
      $base.as((v, t, t2) => _UserSettingsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class UserSettingsCopyWith<$R, $In extends UserSettings, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? isRecordingEnabled, bool? isTranscriptionEnabled});
  UserSettingsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _UserSettingsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, UserSettings, $Out>
    implements UserSettingsCopyWith<$R, UserSettings, $Out> {
  _UserSettingsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<UserSettings> $mapper =
      UserSettingsMapper.ensureInitialized();
  @override
  $R call({bool? isRecordingEnabled, bool? isTranscriptionEnabled}) => $apply(
    FieldCopyWithData({
      if (isRecordingEnabled != null) #isRecordingEnabled: isRecordingEnabled,
      if (isTranscriptionEnabled != null)
        #isTranscriptionEnabled: isTranscriptionEnabled,
    }),
  );
  @override
  UserSettings $make(CopyWithData data) => UserSettings(
    isRecordingEnabled: data.get(
      #isRecordingEnabled,
      or: $value.isRecordingEnabled,
    ),
    isTranscriptionEnabled: data.get(
      #isTranscriptionEnabled,
      or: $value.isTranscriptionEnabled,
    ),
  );

  @override
  UserSettingsCopyWith<$R2, UserSettings, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _UserSettingsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

