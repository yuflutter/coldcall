import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/user_session/_user_session_vm.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:coldcall/features/recorder/_recorder_recognizer_vm_impl.dart';
import 'package:coldcall/features/recorder/recognizer_service_vosk.dart';
import 'package:coldcall/features/recorder/recognizer_service_sherpa_sync.dart';
import 'package:coldcall/features/recorder/recognizer_service_sherpa_isolate.dart';

/// Реализации конфига могут быть разные для разных регионов и вариантов сборок
class AppConfig {
  /// Regex для поиска телефонных номеров в видеокадре
  final phoneNumberRegex = RegExp(
    r'(?:\+?\d{1,3}[\s\-\.]?)?' // Код страны (+7, 8)
    r'(?:\(\d{3,5}\)|\d{3,5})' // Код города/оператора (3-5 цифр)
    r'[\s\-\.]?' // Разделитель
    r'\d{3,7}' // Основной номер (гибкая длина)
    r'(?:[\s\-\.]?\d{2,4})*', // Хвосты номера
    multiLine: true,
  );

  /// Приведение номера к состоянию уникального ключа
  String cleanPhoneNumber(String phone) {
    // Удаляем все символы кроме цифр и +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Заменяем 8 в начале на +7 для российских номеров
    if (cleaned.startsWith('8') && cleaned.length == 11) {
      cleaned = '+7${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Проверяем очищенный номер - является ли он номером телефона (слабовато, ну да ладно)
  bool isPhoneNumber(String cleanNumber) => (cleanNumber.length >= 10);

  /// Форматтер для показа номера перед набором
  final phoneNumberFormatter = MaskTextInputFormatter(
    mask: '+# (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  /// Частота кадров для процессинга видео
  final frameProcessingRate = Duration(milliseconds: 300);

  /// Количество кадров, по достижению которого мы считаем телефонный номер достоверно распознанным
  final reliableCountOfFrames = 2;

  /// Порт синхронизации двух устройств, находящихся в одной сети WiFi
  final historySyncHttpPort = 8084;

  final authorContact = 'https://vk.com/evgeet';
  final supportEmail = 'evgeet@vk.com';
}

/// Внедрение глобальных зависимостей + асинхронные инициализации уровня приложения
Future<void> initApp() async {
  // Инжектим глобальные зависимости
  DI.put(AppConfig());
  DI.put(Err());
  DI.put(UserSessionVm());
  DI.put(Storage());
  // Вьюмодель храним глобально чтобы разворачивать карточку дела при добавлении в дело нового звонка или аудиозаписи
  DI.put(HistoryVm());

  // Внимание!!! Если вы меняете реализацию рекогнайзера - не забудьте скопировать
  // файлы выбранной нейросети в корень папки /assets/
  // Только файлы, лежащие в корне, включается в итоговую сборку!

  // DI.put(RecognizerServiceVosk());
  // DI.put(RecognizerServiceSherpaSync());
  DI.put(RecognizerServiceSherpaIsolate());

  // Вьюмодель храним глобально, чтобы аудиозапись продолжалась при навигации по экранам
  DI.put(RecorderRecognizerVmImpl());

  // Глобальные асинхронные инициализации (контекстные вьюмодели будут инициализированы в соотв. экранах и виджетах)
  await di<UserSessionVm>().init();
  await di<Storage>().init();
}
