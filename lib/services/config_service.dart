import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _keyDatabasePath = 'database_path';
  static const String _keyIsConfigured = 'is_configured';

  static ConfigService? _instance;
  late SharedPreferences _prefs;

  ConfigService._();

  static Future<ConfigService> getInstance() async {
    if (_instance == null) {
      _instance = ConfigService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // 检查是否已配置
  bool get isConfigured {
    return _prefs.getBool(_keyIsConfigured) ?? false;
  }

  // 获取数据库路径
  String? get databasePath {
    return _prefs.getString(_keyDatabasePath);
  }

  // 设置数据库路径
  Future<bool> setDatabasePath(String path) async {
    final success = await _prefs.setString(_keyDatabasePath, path);
    if (success) {
      await _prefs.setBool(_keyIsConfigured, true);
    }
    return success;
  }

  // 清除配置
  Future<bool> clearConfig() async {
    await _prefs.remove(_keyDatabasePath);
    return await _prefs.setBool(_keyIsConfigured, false);
  }
}
