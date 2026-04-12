// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'storage_bundle.dart';

class StorageBundleMapper extends ClassMapperBase<StorageBundle> {
  StorageBundleMapper._();

  static StorageBundleMapper? _instance;
  static StorageBundleMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StorageBundleMapper._());
      DealMapper.ensureInitialized();
      PhoneNumberMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'StorageBundle';

  static List<Deal> _$deals(StorageBundle v) => v.deals;
  static const Field<StorageBundle, List<Deal>> _f$deals = Field(
    'deals',
    _$deals,
  );
  static List<PhoneNumber> _$phoneBook(StorageBundle v) => v.phoneBook;
  static const Field<StorageBundle, List<PhoneNumber>> _f$phoneBook = Field(
    'phoneBook',
    _$phoneBook,
  );

  @override
  final MappableFields<StorageBundle> fields = const {
    #deals: _f$deals,
    #phoneBook: _f$phoneBook,
  };

  static StorageBundle _instantiate(DecodingData data) {
    return StorageBundle(
      deals: data.dec(_f$deals),
      phoneBook: data.dec(_f$phoneBook),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static StorageBundle fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<StorageBundle>(map);
  }

  static StorageBundle fromJson(String json) {
    return ensureInitialized().decodeJson<StorageBundle>(json);
  }
}

mixin StorageBundleMappable {
  String toJson() {
    return StorageBundleMapper.ensureInitialized().encodeJson<StorageBundle>(
      this as StorageBundle,
    );
  }

  Map<String, dynamic> toMap() {
    return StorageBundleMapper.ensureInitialized().encodeMap<StorageBundle>(
      this as StorageBundle,
    );
  }

  StorageBundleCopyWith<StorageBundle, StorageBundle, StorageBundle>
  get copyWith => _StorageBundleCopyWithImpl<StorageBundle, StorageBundle>(
    this as StorageBundle,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return StorageBundleMapper.ensureInitialized().stringifyValue(
      this as StorageBundle,
    );
  }

  @override
  bool operator ==(Object other) {
    return StorageBundleMapper.ensureInitialized().equalsValue(
      this as StorageBundle,
      other,
    );
  }

  @override
  int get hashCode {
    return StorageBundleMapper.ensureInitialized().hashValue(
      this as StorageBundle,
    );
  }
}

extension StorageBundleValueCopy<$R, $Out>
    on ObjectCopyWith<$R, StorageBundle, $Out> {
  StorageBundleCopyWith<$R, StorageBundle, $Out> get $asStorageBundle =>
      $base.as((v, t, t2) => _StorageBundleCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class StorageBundleCopyWith<$R, $In extends StorageBundle, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Deal, DealCopyWith<$R, Deal, Deal>> get deals;
  ListCopyWith<
    $R,
    PhoneNumber,
    PhoneNumberCopyWith<$R, PhoneNumber, PhoneNumber>
  >
  get phoneBook;
  $R call({List<Deal>? deals, List<PhoneNumber>? phoneBook});
  StorageBundleCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _StorageBundleCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, StorageBundle, $Out>
    implements StorageBundleCopyWith<$R, StorageBundle, $Out> {
  _StorageBundleCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<StorageBundle> $mapper =
      StorageBundleMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Deal, DealCopyWith<$R, Deal, Deal>> get deals =>
      ListCopyWith(
        $value.deals,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(deals: v),
      );
  @override
  ListCopyWith<
    $R,
    PhoneNumber,
    PhoneNumberCopyWith<$R, PhoneNumber, PhoneNumber>
  >
  get phoneBook => ListCopyWith(
    $value.phoneBook,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(phoneBook: v),
  );
  @override
  $R call({List<Deal>? deals, List<PhoneNumber>? phoneBook}) => $apply(
    FieldCopyWithData({
      if (deals != null) #deals: deals,
      if (phoneBook != null) #phoneBook: phoneBook,
    }),
  );
  @override
  StorageBundle $make(CopyWithData data) => StorageBundle(
    deals: data.get(#deals, or: $value.deals),
    phoneBook: data.get(#phoneBook, or: $value.phoneBook),
  );

  @override
  StorageBundleCopyWith<$R2, StorageBundle, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _StorageBundleCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

