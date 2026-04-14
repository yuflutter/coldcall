import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'syncable.mapper.dart';

// Принял спорное архитектурное решение, что синхронизируемые объекты будут мутабельными.
// Не хотелось заморачиваться с заменой ссылок в полносвязном дереве. Хотя все равно пришлось это делать при синхронизации.
// Зато теперь вся логика merge инкапсулирована внутри сущностей. Хотя в случае copyWith() было бы так же.

abstract class Syncable {
  final String id;
  final DateTime created;
  bool _deleted;
  DateTime _lastModified;

  Syncable({final String? id, final DateTime? created, final bool? deleted, final DateTime? lastModified})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
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

  /// Используется стратегия Last Write Wins для всех полей, предполагается что other новее.
  /// Смотри реализацию в конкретном потомке!
  @mustBeOverridden
  @mustCallSuper
  void mergeFrom(Syncable other) {
    _deleted = other.deleted;
    if (_lastModified.isBefore(other._lastModified)) {
      _lastModified = other.lastModified;
    }
  }
}

// -----------------------------------------------------------------------------------

// Упорядоченный список синхронизируемых объектов. Класс сделан с двумя целями:
// 1) запретить простое добавление в конец
// 2) не дублировать алгоритмы insert и merge
@MappableClass()
class SyncableList<T extends Syncable> with SyncableListMappable {
  final List<T> _items;

  SyncableList([final List<T>? items]) : _items = items ?? [];

  // возвращаем итераторы, что не так надежно как List.unmodifiable, но более производительно
  Iterable<T> get all => _items;
  Iterable<T> get notDeleted => _items.where((e) => !e.deleted);
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
      if (it.isOlder(other)) {
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

// -----------------------------------------------------------------------------------

// Словарь синхронизируемых объектов. Класс сделан с двумя целями:
// 1) запретить прямое добавление/изменение значений без merge
// 2) не дублировать алгоритм merge
class SyncableMap<T extends Syncable> {
  final Map<String, T> _items;

  SyncableMap([final Map<String, T>? items]) : _items = items ?? {};

  factory SyncableMap.fromList(List<T> values) {
    final res = SyncableMap<T>();
    for (final value in values) {
      res.add(value);
    }
    return res;
  }

  // Сортируем на лету и возвращаем итератор значений. Предполагается что тут меньше записей будет, чем в SyncableList
  Iterable<T> get all => _items.values;
  Iterable<T> get notDeletedAndSorted => _items.values.where((e) => !e.deleted).sortedBy((item) => item.lastModified);
  int get length => _items.length;

  T? getById(String id) => _items[id];

  void add(T item) {
    if (getById(item.id) != null) throw 'SyncableMap already contains item \'${item.id}\'';
    _items[item.id] = item;
  }

  void remove(T item) => _items.remove(item.id);

  T merge(T other) {
    // ищем запись по ID
    var it = _items[other.id];

    // добавляем новую запись
    if (it == null) {
      _items[other.id] = other;
      return other;
    }

    // обновляем поля в существующей записи, возвращаем актуальную объектную ссылку
    if (it != null) {
      if (it.isOlder(other)) {
        it.mergeFrom(other);
        return it;
      } else {
        other.mergeFrom(it);
        _items[it.id] = other;
        return other;
      }
    }
  }
}
