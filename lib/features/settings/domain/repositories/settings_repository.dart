import '../entities/settings.dart';

/// 설정 리포지토리 인터페이스
abstract class SettingsRepository {
  /// 앱 설정 가져오기
  Future<AppSettings?> getAppSettings(String userId);

  /// 앱 설정 저장
  Future<SettingsUpdateResult> saveAppSettings(
      String userId, AppSettings settings);

  /// 설정 초기화 (기본값으로)
  Future<SettingsUpdateResult> resetSettings(String userId);

  /// 설정 변경사항 스트림
  Stream<AppSettings?> watchSettings(String userId);
}
