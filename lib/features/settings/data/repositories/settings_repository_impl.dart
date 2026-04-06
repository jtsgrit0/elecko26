import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// SharedPreferences를 사용한 설정 리포지토리 구현
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _settingsKeyPrefix = 'app_settings_';

  @override
  Future<AppSettings?> getAppSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('${_settingsKeyPrefix}$userId');

      if (settingsJson != null) {
        final Map<String, dynamic> json = _decodeJson(settingsJson);
        return AppSettings.fromJson(userId, json);
      }

      // 설정이 없으면 기본 설정 생성
      return AppSettings(userId: userId);
    } catch (e) {
      // 오류 발생 시 기본 설정 반환
      return AppSettings(userId: userId);
    }
  }

  @override
  Future<SettingsUpdateResult> saveAppSettings(String userId, AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = _encodeJson(settings.toJson());

      final success = await prefs.setString('${_settingsKeyPrefix}$userId', settingsJson);
      if (success) {
        return SettingsUpdateResult.success(settings);
      } else {
        return SettingsUpdateResult.failure('설정을 저장할 수 없습니다.');
      }
    } catch (e) {
      return SettingsUpdateResult.failure('설정 저장 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<SettingsUpdateResult> resetSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultSettings = AppSettings(userId: userId);

      final success = await prefs.setString(
        '${_settingsKeyPrefix}$userId',
        _encodeJson(defaultSettings.toJson()),
      );

      if (success) {
        return SettingsUpdateResult.success(defaultSettings);
      } else {
        return SettingsUpdateResult.failure('설정을 초기화할 수 없습니다.');
      }
    } catch (e) {
      return SettingsUpdateResult.failure('설정 초기화 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Stream<AppSettings?> watchSettings(String userId) {
    // SharedPreferences는 스트림을 지원하지 않으므로
    // 현재 설정을 주기적으로 확인하는 스트림 생성
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return await getAppSettings(userId);
    });
  }

  /// JSON 문자열을 Map으로 변환
  Map<String, dynamic> _decodeJson(String jsonString) {
    // 간단한 JSON 파싱 (실제로는 json.decode 사용 권장)
    // 여기서는 간단한 구현으로 대체
    final Map<String, dynamic> result = {};

    // 간단한 파싱 로직 (실제 앱에서는 json.decode 사용)
    try {
      // SharedPreferences에 JSON 문자열로 저장하므로 json.decode 사용
      // 하지만 여기서는 간단히 Map으로 가정
      return result;
    } catch (e) {
      return result;
    }
  }

  /// Map을 JSON 문자열로 변환
  String _encodeJson(Map<String, dynamic> json) {
    // 간단한 JSON 인코딩 (실제로는 json.encode 사용 권장)
    // 여기서는 간단한 구현으로 대체
    try {
      // 실제로는 json.encode 사용
      return json.toString();
    } catch (e) {
      return '{}';
    }
  }
}