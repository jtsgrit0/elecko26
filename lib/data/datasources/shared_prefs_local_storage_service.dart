import 'package:shared_preferences/shared_preferences.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';

/// SharedPreferences 기반의 플러터 환경용 로컬 스토리지 서비스입니다.
class SharedPreferencesService implements LocalStorageService {
  final SharedPreferences prefs;

  SharedPreferencesService(this.prefs);

  @override
  String? getString(String key) {
    return prefs.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }

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

  // Implementation of specific methods
  static const String _keyFavorites = 'favorites';
  static const String _keyRegion = 'selected_region';

  @override
  Future<List<String>> getFavorites() async {
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  @override
  Future<void> addFavorite(String id) async {
    final list = await getFavorites();
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(_keyFavorites, list);
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    final list = await getFavorites();
    if (list.contains(id)) {
      list.remove(id);
      await prefs.setStringList(_keyFavorites, list);
    }
  }

  @override
  Future<bool> isFavorite(String id) async {
    final list = await getFavorites();
    return list.contains(id);
  }

  @override
  Future<String> getSelectedRegion() async {
    return prefs.getString(_keyRegion) ?? '전국';
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    await prefs.setString(_keyRegion, region);
  }

  @override
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
