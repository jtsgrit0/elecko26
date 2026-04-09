/// 순수 다트 환경(CLI)과 Flutter 환경(App) 간의 의존성 충돌을 방지하기 위한
/// 로컬 스토리지 추상화 인터페이스입니다.
abstract class LocalStorageService {
  String? getString(String key);
  Future<bool> setString(String key, String value);
  List<String>? getStringList(String key);
  Future<bool> setStringList(String key, List<String> value);
  Future<bool> clear();

  // Settings specific
  Future<List<String>> getFavorites();
  Future<void> addFavorite(String id);
  Future<void> removeFavorite(String id);
  Future<bool> isFavorite(String id);
  Future<String> getSelectedRegion();
  Future<void> saveSelectedRegion(String region);
  Future<void> clearAll();

  // 투표 관련
  /// 특정 선거구(district)에 투표한 후보 ID 저장
  Future<void> saveVote(String district, String memberId);
  /// 특정 선거구에 투표한 후보 ID 반환 (없으면 null)
  Future<String?> getVote(String district);
  /// 모든 투표 기록 가져오기 {district: memberId}
  Future<Map<String, String>> getAllVotes();
  /// 특정 선거구 투표 취소
  Future<void> removeVote(String district);
}
