import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _storageKey = 'save_location';
  static const _customPathKey = 'custom_save_path';

  Future<String> getSaveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey) ?? 'internal';
  }

  Future<void> setSaveLocation(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, value);
  }

  Future<String?> getCustomSavePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customPathKey);
  }

  Future<void> setCustomSavePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customPathKey, path);
  }
}
