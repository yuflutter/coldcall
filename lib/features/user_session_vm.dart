import 'package:coldcall/core/simple_change_notifier.dart';
import 'package:coldcall/entities/_all_syncable_entities.dart';
import 'package:coldcall/entities/user_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSessionVm with SimpleChangeNotifier {
  static const _storageKey = 'user_settings';

  UserSettings all = UserSettings(isRecordingEnabled: true, isTranscriptionEnabled: true);

  // одноразовый флаг с геттером
  Deal? _turnToRecordForDeal;

  Deal? get turnToRecordForDeal {
    final res = _turnToRecordForDeal;
    _turnToRecordForDeal = null;
    return res;
  }

  void startRecordForDeal(Deal deal) {
    notify(() => _turnToRecordForDeal = deal);
  }

  late final PackageInfo packageInfo;

  Future<void> initFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);

    if (json != null) {
      try {
        notify(() => all = UserSettingsMapper.fromJson(json));
      } catch (e) {
        print(e);
        await prefs.remove(_storageKey);
      }
    }

    packageInfo = await PackageInfo.fromPlatform();
  }

  void setRecordingEnabled(bool v) {
    notify(() => all = all.copyWith(isRecordingEnabled: v));
    _saveSettings();
  }

  void setTranscriptionEnabled(bool v) {
    notify(() => all = all.copyWith(isTranscriptionEnabled: v));
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, all.toJson());
    } catch (e) {
      print(e);
    }
  }
}
