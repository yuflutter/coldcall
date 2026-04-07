// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'phone_numbers.dart';

class PhoneNumberMapper extends ClassMapperBase<PhoneNumber> {
  PhoneNumberMapper._();

  static PhoneNumberMapper? _instance;
  static PhoneNumberMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PhoneNumberMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PhoneNumber';

  static String _$originNumber(PhoneNumber v) => v.originNumber;
  static const Field<PhoneNumber, String> _f$originNumber = Field(
    'originNumber',
    _$originNumber,
  );
  static String _$cleanNumber(PhoneNumber v) => v.cleanNumber;
  static const Field<PhoneNumber, String> _f$cleanNumber = Field(
    'cleanNumber',
    _$cleanNumber,
    mode: FieldMode.member,
  );
  static String _$formattedNumber(PhoneNumber v) => v.formattedNumber;
  static const Field<PhoneNumber, String> _f$formattedNumber = Field(
    'formattedNumber',
    _$formattedNumber,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<PhoneNumber> fields = const {
    #originNumber: _f$originNumber,
    #cleanNumber: _f$cleanNumber,
    #formattedNumber: _f$formattedNumber,
  };

  static PhoneNumber _instantiate(DecodingData data) {
    return PhoneNumber(originNumber: data.dec(_f$originNumber));
  }

  @override
  final Function instantiate = _instantiate;

  static PhoneNumber fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PhoneNumber>(map);
  }

  static PhoneNumber fromJson(String json) {
    return ensureInitialized().decodeJson<PhoneNumber>(json);
  }
}

mixin PhoneNumberMappable {
  String toJson() {
    return PhoneNumberMapper.ensureInitialized().encodeJson<PhoneNumber>(
      this as PhoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return PhoneNumberMapper.ensureInitialized().encodeMap<PhoneNumber>(
      this as PhoneNumber,
    );
  }

  PhoneNumberCopyWith<PhoneNumber, PhoneNumber, PhoneNumber> get copyWith =>
      _PhoneNumberCopyWithImpl<PhoneNumber, PhoneNumber>(
        this as PhoneNumber,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PhoneNumberMapper.ensureInitialized().stringifyValue(
      this as PhoneNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    return PhoneNumberMapper.ensureInitialized().equalsValue(
      this as PhoneNumber,
      other,
    );
  }

  @override
  int get hashCode {
    return PhoneNumberMapper.ensureInitialized().hashValue(this as PhoneNumber);
  }
}

extension PhoneNumberValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PhoneNumber, $Out> {
  PhoneNumberCopyWith<$R, PhoneNumber, $Out> get $asPhoneNumber =>
      $base.as((v, t, t2) => _PhoneNumberCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PhoneNumberCopyWith<$R, $In extends PhoneNumber, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? originNumber});
  PhoneNumberCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PhoneNumberCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PhoneNumber, $Out>
    implements PhoneNumberCopyWith<$R, PhoneNumber, $Out> {
  _PhoneNumberCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PhoneNumber> $mapper =
      PhoneNumberMapper.ensureInitialized();
  @override
  $R call({String? originNumber}) => $apply(
    FieldCopyWithData({if (originNumber != null) #originNumber: originNumber}),
  );
  @override
  PhoneNumber $make(CopyWithData data) => PhoneNumber(
    originNumber: data.get(#originNumber, or: $value.originNumber),
  );

  @override
  PhoneNumberCopyWith<$R2, PhoneNumber, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PhoneNumberCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

