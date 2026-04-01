/// 순수 다트 환경(CLI)과 Flutter 환경(App) 간의 의존성 충돌을 방지하기 위한
/// 로컬 스토리지 추상화 인터페이스입니다.
abstract class LocalStorageService {
  List<String>? getStringList(String key);
  Future<bool> setStringList(String key, List<String> value);
  Future<bool> clear();
}
