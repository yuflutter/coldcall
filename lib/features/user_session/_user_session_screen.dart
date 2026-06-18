import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/features/user_session/_user_session_vm.dart';
import 'package:coldcall/features/user_session/app_description.dart';
import 'package:coldcall/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UserSessionScreen extends StatelessWidget {
  const UserSessionScreen({super.key});

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
                    onPressed: () => launchUrlString(di<AppConfig>().authorContact, mode: LaunchMode.externalApplication),
                    child: Text('Связаться с автором', style: TextStyle(fontSize: 18)),
                  ),
                  Gap(20),
                  const Divider(color: Colors.grey),
                  _buildCompressSection(context, model),
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

  Widget _buildCompressSection(BuildContext context, UserSessionVm model) {
    final result = model.lastCompressResult;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Обслуживание базы данных',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Text(
            'Удаляет помеченные на удаление записи из списка сделок и телефонной книги, '
            'а также аудиофайлы без актуальных ссылок.',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const Gap(12),
          if (result != null) ...[_CompressResultWidget(result: result), const Gap(8)],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: model.isCompressing ? null : () => model.compressStorage(),
              icon: model.isCompressing
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.compress),
              label: Text(model.isCompressing ? 'Сжатие...' : 'Сжать базу данных'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.deepOrange.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompressResultWidget extends StatelessWidget {
  final StorageCompressResult result;

  const _CompressResultWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasChanges) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const Gap(6),
          Text('База данных уже в порядке — нечего удалять.', style: TextStyle(color: Colors.green, fontSize: 13)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const Gap(6),
              Text(
                'Сжатие выполнено:',
                style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (result.dealsRemoved > 0) _row('Удалено сделок', result.dealsRemoved),
          if (result.phoneBookRemoved > 0) _row('Удалено записей из телефонной книги', result.phoneBookRemoved),
          if (result.audioFilesRemoved > 0) _row('Удалено аудиофайлов', result.audioFilesRemoved),
        ],
      ),
    );
  }

  Widget _row(String label, int count) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('  • $label: $count', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
  );
}
