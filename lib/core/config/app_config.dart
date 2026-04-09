class AppConfig {
  /// Firebase 연동 모드 토글 (설정이 완료되지 않았다면 false로 두어 로컬 구동 유지)
  static const bool enableFirebase = false;

  /// 여론조사 데이터 (nesdc_polls.json) GitHub Raw 주소
  static const String nesdcDataUrl = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/nesdc_polls.json';
}
