/// 애플리케이션 상수 정의
class AppConstants {
  // API 설정
  static const String baseUrl = 'https://api.example.com';
  static const String crawlBaseUrl = 'https://crawl.example.com';
  
  // 타임아웃
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // 캐시
  static const Duration cacheDuration = Duration(hours: 6);
  
  // 업데이트 주기
  static const Duration updateInterval = Duration(hours: 1);
  
  // 앱 정보
  static const String appName = '국회의원 AI 분석 플랫폼';
  static const String appVersion = '1.0.0';
}
