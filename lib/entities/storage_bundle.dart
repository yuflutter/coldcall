import 'package:coldcall/entities/deal.dart';
import 'package:coldcall/entities/phone_numbers.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'storage_bundle.mapper.dart';

// Данные хранятся на диске и отправляются для синхронизации единым json
@MappableClass()
class StorageBundle with StorageBundleMappable {
  final List<Deal> deals;
  final List<PhoneNumber> phoneBook;

  StorageBundle({required this.deals, required this.phoneBook});
}
