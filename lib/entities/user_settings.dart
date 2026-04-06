import 'package:dart_mappable/dart_mappable.dart';

part 'user_settings.mapper.dart';

@MappableClass()
class UserSettings with UserSettingsMappable {
  final bool isRecordingEnabled;
  final bool isTranscriptionEnabled;

  const UserSettings({required this.isRecordingEnabled, required this.isTranscriptionEnabled});
}
