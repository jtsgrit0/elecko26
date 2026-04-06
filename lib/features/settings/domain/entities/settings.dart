/// 설정 관련 엔티티들

/// 앱 설정 엔티티
class AppSettings {
  final String userId;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String language;
  final bool autoRefreshEnabled;
  final int refreshIntervalMinutes;
  final bool showImages;
  final bool soundEnabled;
  final Map<String, dynamic>? customSettings;

  AppSettings({
    required this.userId,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'ko',
    this.autoRefreshEnabled = true,
    this.refreshIntervalMinutes = 30,
    this.showImages = true,
    this.soundEnabled = true,
    this.customSettings,
  });

  AppSettings copyWith({
    String? userId,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
    bool? autoRefreshEnabled,
    int? refreshIntervalMinutes,
    bool? showImages,
    bool? soundEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettings(
      userId: userId ?? this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshIntervalMinutes: refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      showImages: showImages ?? this.showImages,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// SharedPreferences에서 변환
  factory AppSettings.fromJson(String userId, Map<String, dynamic> json) {
    return AppSettings(
      userId: userId,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      language: json['language'] ?? 'ko',
      autoRefreshEnabled: json['autoRefreshEnabled'] ?? true,
      refreshIntervalMinutes: json['refreshIntervalMinutes'] ?? 30,
      showImages: json['showImages'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      customSettings: json['customSettings'],
    );
  }

  /// SharedPreferences로 변환
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'language': language,
      'autoRefreshEnabled': autoRefreshEnabled,
      'refreshIntervalMinutes': refreshIntervalMinutes,
      'showImages': showImages,
      'soundEnabled': soundEnabled,
      'customSettings': customSettings,
    };
  }
}

/// 설정 업데이트 결과
class SettingsUpdateResult {
  final bool isSuccess;
  final String? errorMessage;
  final AppSettings? updatedSettings;

  SettingsUpdateResult({
    required this.isSuccess,
    this.errorMessage,
    this.updatedSettings,
  });

  factory SettingsUpdateResult.success(AppSettings settings) {
    return SettingsUpdateResult(
      isSuccess: true,
      updatedSettings: settings,
    );
  }

  factory SettingsUpdateResult.failure(String errorMessage) {
    return SettingsUpdateResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// 지원되는 언어
enum SupportedLanguage {
  korean('ko', '한국어'),
  english('en', 'English');

  const SupportedLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

/// 지원되는 테마
enum AppTheme {
  light('light', '밝은 테마'),
  dark('dark', '어두운 테마'),
  system('system', '시스템 설정');

  const AppTheme(this.code, this.displayName);
  final String code;
  final String displayName;
}