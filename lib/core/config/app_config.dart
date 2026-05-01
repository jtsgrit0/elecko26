class AppConfig {
  /// Firebase 연동 모드 토글 (설정이 완료되지 않았다면 false로 두어 로컬 구동 유지)
  static const bool enableFirebase = true;

  /// 여론조사 데이터 (nesdc_polls.json) GitHub Raw 주소
  static const String nesdcDataUrl =
      'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/nesdc_polls.json';

  /// NESDC 크롤링 프록시 서버 주소
  static const String kNesdcBaseUrl = 'https://elecko-nesdc-proxy.fly.io';

  static const String kDefaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
}
