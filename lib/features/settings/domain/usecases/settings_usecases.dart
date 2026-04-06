import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

/// 설정 유스케이스 베이스 클래스
abstract class SettingsUseCase {
  final SettingsRepository repository;

  SettingsUseCase(this.repository);
}

/// 앱 설정 가져오기 유스케이스
class GetAppSettingsUseCase extends SettingsUseCase {
  GetAppSettingsUseCase(super.repository);

  Future<AppSettings?> execute(String userId) async {
    return await repository.getAppSettings(userId);
  }
}

/// 앱 설정 저장 유스케이스
class SaveAppSettingsUseCase extends SettingsUseCase {
  SaveAppSettingsUseCase(super.repository);

  Future<SettingsUpdateResult> execute(String userId, AppSettings settings) async {
    return await repository.saveAppSettings(userId, settings);
  }
}

/// 설정 초기화 유스케이스
class ResetSettingsUseCase extends SettingsUseCase {
  ResetSettingsUseCase(super.repository);

  Future<SettingsUpdateResult> execute(String userId) async {
    return await repository.resetSettings(userId);
  }
}

/// 알림 설정 토글 유스케이스
class ToggleNotificationsUseCase extends SettingsUseCase {
  ToggleNotificationsUseCase(super.repository);

  Future<SettingsUpdateResult> execute(String userId, bool enabled) async {
    final currentSettings = await repository.getAppSettings(userId);
    if (currentSettings == null) return SettingsUpdateResult.failure('설정을 불러올 수 없습니다.');

    final updatedSettings = currentSettings.copyWith(notificationsEnabled: enabled);
    return await repository.saveAppSettings(userId, updatedSettings);
  }
}

/// 다크 모드 토글 유스케이스
class ToggleDarkModeUseCase extends SettingsUseCase {
  ToggleDarkModeUseCase(super.repository);

  Future<SettingsUpdateResult> execute(String userId, bool enabled) async {
    final currentSettings = await repository.getAppSettings(userId);
    if (currentSettings == null) return SettingsUpdateResult.failure('설정을 불러올 수 없습니다.');

    final updatedSettings = currentSettings.copyWith(darkModeEnabled: enabled);
    return await repository.saveAppSettings(userId, updatedSettings);
  }
}

/// 언어 변경 유스케이스
class ChangeLanguageUseCase extends SettingsUseCase {
  ChangeLanguageUseCase(super.repository);

  Future<SettingsUpdateResult> execute(String userId, String languageCode) async {
    final currentSettings = await repository.getAppSettings(userId);
    if (currentSettings == null) return SettingsUpdateResult.failure('설정을 불러올 수 없습니다.');

    final updatedSettings = currentSettings.copyWith(language: languageCode);
    return await repository.saveAppSettings(userId, updatedSettings);
  }
}