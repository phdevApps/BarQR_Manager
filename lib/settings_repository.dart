import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _storageKey = 'save_location';

  Future<String> getSaveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey) ?? 'internal';
  }

  Future<void> setSaveLocation(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, value);
  }
}