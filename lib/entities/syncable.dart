import 'package:dart_mappable/dart_mappable.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'syncable.mapper.dart';

// Принял спорное архитектурное решение, что синхронизируемые объекты будут мутабельными.
// Не хотелось заморачиваться с заменой ссылок в полносвязном дереве. Хотя все равно пришлось это делать при синхронизации.
// Зато теперь вся логика merge инкапсулирована внутри сущностей. Хотя в случае copyWith() было бы так же.

abstract class Syncable {
  final int id;
  final DateTime created;
  bool _deleted;
  DateTime _lastModified;

  Syncable({final int? id, final DateTime? created, final bool? deleted, final DateTime? lastModified})
    : id = id ?? DateTime.now().microsecondsSinceEpoch,
      created = created ?? DateTime.now(),
      _deleted = deleted ?? false,
      _lastModified = lastModified ?? DateTime.now();

  bool get deleted => _deleted;
  void markDeleted({bool raw = false}) {
    if (!raw) {
      update(() => _deleted = true);
    } else {
      _deleted = true;
    }
  }

  DateTime get lastModified => _lastModified;

  bool isOlder(Syncable other) => lastModified.isBefore(other.lastModified);
  bool isNewer(Syncable other) => lastModified.isAfter(other.lastModified);

  /// использовать во всех потомках при ручном обновлении полей
  @mustCallSuper
  void update(VoidCallback? updater, {bool raw = false}) {
    updater?.call();
    if (!raw) _lastModified = DateTime.now();
  }

  /// Используется стратегия Last Write Wins для всех полей
  @mustBeOverridden
  @mustCallSuper
  void mergeFrom(Syncable other) {
    _deleted = other.deleted;
  }
}

// ---------------------------------------------------------------------------------------------

// Упорядоченный список синхронизируемых объектов. Класс сделан с двумя целями:
// 1) запретить простое добавление в конец
// 2) не дублировать алгоритмы insert и merge
@MappableClass()
class SyncableList<T extends Syncable> with SyncableListMappable {
  final List<T> _items;

  SyncableList([final List<T>? items]) : _items = items ?? [];

  // возвращаем итератор, что не так надежно как иммутабельный лист, но более производительно
  Iterable<T> get items => _items.where((e) => !e.deleted);
  int get length => _items.length;

  // поскольку список упорядоченный - запрещаем простое добавление, только вставка в нужное место по дате
  // void add(T item) => _items.add(item);

  Future<void> insert(T item) async {
    for (var i = _items.length - 1; i >= 0; i--) {
      final it = _items[i];
      if (it.isOlder(item)) {
        _items.insert(i + 1, item);
        return;
      }
    }
    _items.insert(0, item);
  }

  void remove(T item) => _items.remove(item);

  void merge(T other, bool Function(T item1, T intem2) softMergeCondition) {
    // ищем запись по ID
    var it = _items.firstWhereOrNull((e) => e.id == other.id);

    if (it == null) {
      // Ищем похожую запись по мягкому условию, после чего объединяем две в одну
      it = _items.firstWhereOrNull((e) => softMergeCondition(e, other));

      // добавляем новую запись
      if (it == null) {
        insert(other);
        return;
      }
    }

    // обновляем поля в существующей записи, и перепозиционируем ее в упорядоченном списке
    if (it != null) {
      if (it.isNewer(other)) {
        it.mergeFrom(other);
        remove(it);
        insert(it);
      } else {
        other.mergeFrom(it);
        remove(it);
        insert(other);
      }
    }
  }
}
