import 'dart:async';

import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// 플러그인 없이 동작하는 메모리 기반 설정 리포지토리 구현
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _settingsKeyPrefix = 'app_settings_';
  static final Map<String, AppSettings> _settingsStore = {};

  @override
  Future<AppSettings?> getAppSettings(String userId) async {
    try {
      final settings = _settingsStore['${_settingsKeyPrefix}$userId'];
      if (settings != null) {
        return settings;
      }

      return AppSettings(userId: userId);
    } catch (e) {
      return AppSettings(userId: userId);
    }
  }

  @override
  Future<SettingsUpdateResult> saveAppSettings(String userId, AppSettings settings) async {
    try {
      _settingsStore['${_settingsKeyPrefix}$userId'] = settings;
      return SettingsUpdateResult.success(settings);
    } catch (e) {
      return SettingsUpdateResult.failure('설정 저장 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<SettingsUpdateResult> resetSettings(String userId) async {
    try {
      final defaultSettings = AppSettings(userId: userId);
      _settingsStore['${_settingsKeyPrefix}$userId'] = defaultSettings;
      return SettingsUpdateResult.success(defaultSettings);
    } catch (e) {
      return SettingsUpdateResult.failure('설정 초기화 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Stream<AppSettings?> watchSettings(String userId) {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return await getAppSettings(userId);
    });
  }
}
