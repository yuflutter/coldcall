/// Простейший DI для глобальных зависимостей.
/// Поддерживает полиморфизм и затенение по стеку. Используется в слоях, где недоступен BuildContext.
/// Производительность практически аналогична Map при небольшом количестве элементов.
class DI {
  static final List<Object> _instances = [];

  static void put(Object instance) => _instances.insert(0, instance);

  static void putAll(List<Object> instances) => instances.forEach(put);

  static Future<void> putAndInit(Initializable instance) {
    _instances.insert(0, instance);
    return instance.init();
  }

  static Future<void> putAndInitAll(List<Initializable> instances) {
    return Future.wait(instances.map(putAndInit).toList());
  }

  static T get<T>() {
    for (final i in _instances) {
      if (i is T) return i as T;
    }
    throw 'Instance of $T is not found in global DI';
  }
}

/// Краткий синоним для DI.get()
T di<T>() => DI.get<T>();

/// Асинхронный нициализатор для глобальных объектов.
/// Глобальные зависимости инициализируются при старте главной страницы, с выводом ошибок туда же.
abstract class Initializable {
  Future<void> init();
}

/// Для использования в моделях, которые не являются ChangeNotifier,
/// но содержат внутри контроллеры, например TextEditingController и др.
abstract class Disposable {
  void dispose();
}

///-------------------------------------------------
/// Пример использования с полиморфизмом
void exampleOfUseDI() {
  DI.put(_MyUserSession());
  // ignore: avoid_print
  print(di<_AbstractUserSession>());
  // ignore: avoid_print
  print(di<_MyUserSession>());
}

class _AbstractUserSession {}

class _MyUserSession extends _AbstractUserSession {}
