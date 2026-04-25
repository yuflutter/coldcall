import 'package:coldcall/core/log.dart';
import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'syncable.mapper.dart';

// Принял спорное архитектурное решение, что все синхронизируемые объекты будут мутабельными.
// Не хотелось заморачиваться с заменой ссылок в полносвязном дереве. Хотя все равно пришлось это делать при синхронизации.
// Зато теперь вся логика merge инкапсулирована внутри сущностей. Хотя в случае copyWith() все было бы так же.

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
  void markDeleted({bool raw = false}) => update(() => _deleted = true, raw: raw);

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

// Список синхронизируемых объектов.  Класс сделан с двумя целями:
// 1) запретить добавление без merge
// 2) не дублировать алгоритм merge
@MappableClass()
class SyncableList<T extends Syncable> with SyncableListMappable {
  final List<T> _items;

  SyncableList([final List<T>? items]) : _items = items ?? [];

  // Возвращаем итераторы для производительности (дальше они будут сортироваться) и безопасности (относительной)
  Iterable<T> get all => _items;
  Iterable<T> get notDeleted => _items.where((e) => !e.deleted);

  void _add(T item) {
    // всегда ищем только среди неудаленных! удаленные остаются при переносе записей между делами!
    if (notDeleted.any((e) => e.id == item.id)) {
      throw 'SyncableList already contains item "${item.id}"';
    }
    _items.add(item);
  }

  // void reload(List<T> items) {
  //   _items.clear();
  //   _items.addAll(items);
  // }

  // Поскольку у нас синхронизация, ничего не удаляем, а только помечаем удаленным
  // void remove(T item) {
  //   _items.remove(item);
  // }

  void merge(T other, {bool Function(T item1, T intem2)? softMergeCondition}) {
    // ищем запись по ID
    // всегда ищем только среди неудаленных! удаленные остаются при переносе записей между делами!
    var it = notDeleted.firstWhereOrNull((e) => e.id == other.id);

    if (it == null && softMergeCondition != null) {
      // ищем похожую запись по мягкому условию, после чего объединяем две в одну
      it = notDeleted.firstWhereOrNull((e) => softMergeCondition(e, other));
    }

    // добавляем новую запись
    if (it == null) {
      _add(other);
      return;
    }

    // обновляем поля в существующей записи (выбираем более старую, и доводим до состояния новой)
    if (it != null && it != other && it.lastModified != other.lastModified) {
      if (it.isOlder(other)) {
        it.mergeFrom(other);
        Log.deb('it.mergeFrom(other)');
      } else {
        other.mergeFrom(it);
        it.markDeleted();
        _add(other);
        Log.deb('other.mergeFrom(it)');
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
      res._add(value);
    }
    return res;
  }

  // Возвращаем итераторы для производительности (дальше они будут сортироваться) и безопасности (относительной)
  Iterable<T> get all => _items.values;
  Iterable<T> get notDeleted => _items.values.where((e) => !e.deleted);

  T? getById(String id) => _items[id];

  void _add(T item) {
    // TODO: возможно нужно искать только среди неудаленных? Смотри как сделано в SyncableList!
    if (getById(item.id) != null) {
      throw 'SyncableMap already contains item "${item.id}"';
    }
    _items[item.id] = item;
  }

  // Поскольку у нас синхронизация, ничего не удаляем, а только помечаем удаленным
  // void remove(T item) {
  //   _items.remove(item.id);
  // }

  T merge(T other) {
    // ищем запись по ID
    var it = _items[other.id];

    // добавляем новую запись
    if (it == null) {
      _items[other.id] = other;
      return other;
    }

    // обновляем поля в существующей записи, возвращаем актуальную объектную ссылку
    // специально оставил это "мертвое" условие, чтобы сохранить подобие с SyncableList, и ты не ошибся при рефакторинге
    if (it != null && it != other && it.lastModified != other.lastModified) {
      if (it.isOlder(other)) {
        it.mergeFrom(other);
        return it;
      } else {
        other.mergeFrom(it);
        _items[it.id] = other;
        return other;
      }
    } else {
      return it;
    }
  }
}
