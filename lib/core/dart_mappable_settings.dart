import 'package:dart_mappable/dart_mappable.dart';

// Мапперы для сериализации нестандартных типов

class DurationMsMapper extends SimpleMapper<Duration> {
  const DurationMsMapper();
  @override
  Duration decode(dynamic value) => Duration(milliseconds: value as int);
  @override
  int encode(Duration value) => value.inMilliseconds;
}

class ForceLocalDateTimeMapper extends DateTimeMapper {
  const ForceLocalDateTimeMapper();
  @override
  DateTime decode(dynamic value) {
    DateTime dt = super.decode(value);
    return dt.toLocal();
  }
}

void registerJsonMappers() {
  MapperContainer.globals
    ..use(const DurationMsMapper())
    ..use(const ForceLocalDateTimeMapper());
}

// Хуки для полей

class NullMappableFieldHook extends MappingHook {
  const NullMappableFieldHook();
  @override
  Object? beforeEncode(Object? value) {
    return super.beforeEncode(null);
  }
}
