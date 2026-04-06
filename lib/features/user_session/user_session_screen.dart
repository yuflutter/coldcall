import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/user_session/user_session_vm.dart';
import 'package:coldcall/widgets/contact_author_widget.dart';
import 'package:flutter/material.dart';

class UserSessionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = di<UserSessionVm>();

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text('О приложении'), backgroundColor: Colors.black, foregroundColor: Colors.white),
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              ListView(
                children: [
                  // const SizedBox(height: 20),
                  // _buildSectionTitle('Запись звонков'),
                  // _buildSwitchTile(
                  //   title: 'Включить запись',
                  //   subtitle: 'Записывать звонки автоматически',
                  //   value: model.all.isRecordingEnabled,
                  //   onChanged: (v) => model.setRecordingEnabled(v),
                  // ),
                  // _buildSwitchTile(
                  //   title: 'Автоматическая расшифровка',
                  //   subtitle: 'Преобразовывать речь в текст во время звонка',
                  //   value: model.all.isTranscriptionEnabled,
                  //   onChanged: (v) => model.setTranscriptionEnabled(v),
                  // ),
                  // const Divider(color: Colors.grey),
                  // const SizedBox(height: 20),
                  _buildInfoTile(title: 'Имя:', subtitle: ' ${model.packageInfo.appName}'),
                  _buildInfoTile(title: 'Версия', subtitle: model.packageInfo.version),
                  _buildInfoTile(title: 'Разработчик', subtitle: 'evgeet'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Text(
                      'Мобильное приложение распознаёт телефонные номера при наведении камеры, обводит рамкой, и совершает звонок при наведении прицела на номер (или автоматически, если в кадре только один номер). Работает офлайн, не требует доступа к интернету. Для распознавания номеров используется google_mlkit_text_recognition, который отлично умеет распознавать печатный текст в любой ориентации, но плохо понимает рукописный.\n\n'
                      'Приложение также умеет работать в режиме диктофона, записывая голос и одновременно текстовую расшифровку речи. Расшифровка речи работает офлайн, для этого используются две локальные нейросети на выбор (смотри app_config.dart).\n\n'
                      'Поскольку локальная запись разговора (даже собственного голоса) невозможна во время звонка (микрофон захвачен системным приложением), а использование серверной инфраструктуры противоречит условиям задачи (полноценная работа без доступа к интернету) - предлагается следующее решение. Рядом кладется второй телефон с установленным приложением. Первый телефон работает в режиме звонка, второй в режиме диктофона. При установлении блютуз-соединения - история звонков синхронизируется с историей диктофона, в результате мы получаем на обеих телефонах идентичную историю - метаданные звонка + запись голоса + текстовую расшифровку.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              // Контакты автора
              Positioned(bottom: 20, left: 0, right: 0, child: ContactAuthorWidget()),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildSectionTitle(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     child: Text(
  //       title,
  //       style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
  //     ),
  //   );
  // }

  // Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
  //   return SwitchListTile(
  //     title: Text(title, style: const TextStyle(color: Colors.white)),
  //     subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
  //     value: value,
  //     onChanged: onChanged,
  //     activeThumbColor: Colors.green,
  //   );
  // }

  Widget _buildInfoTile({required String title, required dynamic subtitle}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: (subtitle is Widget) ? subtitle : Text(subtitle, style: TextStyle(color: Colors.grey[400])),
    );
  }
}
