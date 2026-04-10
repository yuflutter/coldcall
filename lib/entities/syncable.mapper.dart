// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'syncable.dart';

class SyncableListMapper extends ClassMapperBase<SyncableList> {
  SyncableListMapper._();

  static SyncableListMapper? _instance;
  static SyncableListMapper ensureInitialized() {
    if (_instance == null) {
      MapperBase.addType<Syncable>();
      MapperContainer.globals.use(_instance = SyncableListMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SyncableList';
  @override
  Function get typeFactory =>
      <T extends Syncable>(f) => f<SyncableList<T>>();

  static List<Syncable> _$_items(SyncableList v) => v._items;
  static dynamic _arg$_items<T extends Syncable>(f) => f<List<T>>();
  static const Field<SyncableList, List<Syncable>> _f$_items = Field(
    '_items',
    _$_items,
    key: r'items',
    opt: true,
    arg: _arg$_items,
  );

  @override
  final MappableFields<SyncableList> fields = const {#_items: _f$_items};

  static SyncableList<T> _instantiate<T extends Syncable>(DecodingData data) {
    return SyncableList(data.dec(_f$_items));
  }

  @override
  final Function instantiate = _instantiate;

  static SyncableList<T> fromMap<T extends Syncable>(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SyncableList<T>>(map);
  }

  static SyncableList<T> fromJson<T extends Syncable>(String json) {
    return ensureInitialized().decodeJson<SyncableList<T>>(json);
  }
}

mixin SyncableListMappable<T extends Syncable> {
  String toJson() {
    return SyncableListMapper.ensureInitialized().encodeJson<SyncableList<T>>(
      this as SyncableList<T>,
    );
  }

  Map<String, dynamic> toMap() {
    return SyncableListMapper.ensureInitialized().encodeMap<SyncableList<T>>(
      this as SyncableList<T>,
    );
  }

  SyncableListCopyWith<SyncableList<T>, SyncableList<T>, SyncableList<T>, T>
  get copyWith =>
      _SyncableListCopyWithImpl<SyncableList<T>, SyncableList<T>, T>(
        this as SyncableList<T>,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SyncableListMapper.ensureInitialized().stringifyValue(
      this as SyncableList<T>,
    );
  }

  @override
  bool operator ==(Object other) {
    return SyncableListMapper.ensureInitialized().equalsValue(
      this as SyncableList<T>,
      other,
    );
  }

  @override
  int get hashCode {
    return SyncableListMapper.ensureInitialized().hashValue(
      this as SyncableList<T>,
    );
  }
}

extension SyncableListValueCopy<$R, $Out, T extends Syncable>
    on ObjectCopyWith<$R, SyncableList<T>, $Out> {
  SyncableListCopyWith<$R, SyncableList<T>, $Out, T> get $asSyncableList =>
      $base.as((v, t, t2) => _SyncableListCopyWithImpl<$R, $Out, T>(v, t, t2));
}

abstract class SyncableListCopyWith<
  $R,
  $In extends SyncableList<T>,
  $Out,
  T extends Syncable
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, T, ObjectCopyWith<$R, T, T>> get _items;
  $R call({List<T>? items});
  SyncableListCopyWith<$R2, $In, $Out2, T> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SyncableListCopyWithImpl<$R, $Out, T extends Syncable>
    extends ClassCopyWithBase<$R, SyncableList<T>, $Out>
    implements SyncableListCopyWith<$R, SyncableList<T>, $Out, T> {
  _SyncableListCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SyncableList> $mapper =
      SyncableListMapper.ensureInitialized();
  @override
  ListCopyWith<$R, T, ObjectCopyWith<$R, T, T>> get _items => ListCopyWith(
    $value._items,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(items: v),
  );
  @override
  $R call({Object? items = $none}) =>
      $apply(FieldCopyWithData({if (items != $none) #items: items}));
  @override
  SyncableList<T> $make(CopyWithData data) =>
      SyncableList(data.get(#items, or: $value._items));

  @override
  SyncableListCopyWith<$R2, SyncableList<T>, $Out2, T> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SyncableListCopyWithImpl<$R2, $Out2, T>($value, $cast, t);
}

