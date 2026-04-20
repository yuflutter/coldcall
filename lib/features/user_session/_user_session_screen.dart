import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/user_session/_user_session_vm.dart';
import 'package:coldcall/features/user_session/app_description.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
                  // _buildInfoTile(title: 'Имя:', subtitle: ' ${model.packageInfo.appName}'),
                  // _buildInfoTile(title: 'Версия', subtitle: model.packageInfo.version),
                  // _buildInfoTile(title: 'Разработчик', subtitle: 'evgeet'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 15),
                    child: Text(
                      '${model.packageInfo.appName}, версия ${model.packageInfo.version}',
                      style: TextStyle(fontSize: 20, color: Colors.yellow),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: SelectableText(appDescription, style: TextStyle(fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () => launchUrlString(di<AppConfig>().authorContact, mode: .externalApplication),
                    child: Text('Связаться с автором', style: TextStyle(fontSize: 18)),
                  ),
                  Gap(20),
                ],
              ),
              // Контакты автора
              // Positioned(bottom: 20, left: 0, right: 0, child: ContactAuthorWidget()),
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

  // Widget _buildInfoTile({required String title, required dynamic subtitle}) {
  //   return ListTile(
  //     title: Text(title, style: const TextStyle(color: Colors.white)),
  //     subtitle: (subtitle is Widget) ? subtitle : Text(subtitle, style: TextStyle(color: Colors.grey[400])),
  //   );
  // }
}
