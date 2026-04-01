import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/data/datasources/local_storage_service.dart';

/// SharedPreferences 기반의 플러터 환경용 로컬 스토리지 서비스입니다.
class SharedPreferencesService implements LocalStorageService {
  final SharedPreferences prefs;

  SharedPreferencesService(this.prefs);

  @override
  List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  @override
  Future<bool> clear() async {
    return await prefs.clear();
  }
}
