import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/history/_history_vm.dart';
import 'package:coldcall/features/user_session/user_session_vm.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:coldcall/features/recorder/_recorder_recognizer_vm_impl.dart';
import 'package:coldcall/features/recorder/recognizer_service_vosk.dart';
import 'package:coldcall/features/recorder/recognizer_service_sherpa_sync.dart';
import 'package:coldcall/features/recorder/recognizer_service_sherpa_isolate.dart';

/// Regex для поиска телефонных номеров
final phoneRegex = RegExp(
  r'(?:\+?\d{1,3}[\s\-\.]?)?' // Код страны (+7, 8)
  r'(?:\(\d{3,5}\)|\d{3,5})' // Код города/оператора (3-5 цифр)
  r'[\s\-\.]?' // Разделитель
  r'\d{3,7}' // Основной номер (гибкая длина)
  r'(?:[\s\-\.]?\d{2,4})*', // Хвосты номера
  multiLine: true,
);

/// Форматтер для показа номера перед набором
final phoneFormatter = MaskTextInputFormatter(
  mask: '+# (###) ###-##-##',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.lazy,
);

/// Частота кадров для процессинга видео
const frameProcessingRate = Duration(milliseconds: 500);

/// Порт синхронизации двух устройств, находящихся в одной сети WiFi
const historySyncHttpPort = 8084;

const authorContact = 'https://vk.com/evgeet';
const supportEmail = 'evgeet@vk.com';

/// Внедрение глобальных зависимостей + асинхронные инициализации уровня приложения
Future<void> initApp() async {
  // Инжектим глобальные зависимости
  DI.put(Err());
  DI.put(UserSessionVm());
  DI.put(HistoryVm());

  // Внимание!!! Если вы меняете реализацию рекогнайзера - не забудьте скопировать
  // файлы выбранной нейросети в корень папки /assets/
  // Только файлы, лежащие в корне, включается в итоговую сборку!

  // DI.put(RecognizerServiceVosk());
  DI.put(RecognizerServiceSherpaSync());
  // DI.put(RecognizerServiceSherpaIsolate());

  // Вьюмодель храним глобально, чтобы запись продолжалась при навигации по экранам
  DI.put(RecorderRecognizerVmImpl());

  // Глобальные асинхронные инициализации (контекстные вьюмодели будут инициализированы в соотв. экранах и виджетах)
  await di<UserSessionVm>().initFromStorage();
  await di<HistoryVm>().initFromStorage();
}
