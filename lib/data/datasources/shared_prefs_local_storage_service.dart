import 'package:shared_preferences/shared_preferences.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:rxdart/rxdart.dart';

/// SharedPreferences 기반의 플러터 환경용 로컬 스토리지 서비스입니다.
class SharedPreferencesService implements LocalStorageService {
  final SharedPreferences prefs;
  final _votesController = BehaviorSubject<Map<String, String>>();

  SharedPreferencesService(this.prefs) {
    // 초기화 시 기존 데이터를 로드하여 스트림에 전송
    _initVotesStream();
  }

  Future<void> _initVotesStream() async {
    final votes = await getAllVotes();
    _votesController.add(votes);
  }

  @override
  Stream<Map<String, String>> watchAllVotes() => _votesController.stream;

  @override
  String? getString(String key) {
    return prefs.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  @override
  Future<bool> clear() async {
    return await prefs.clear();
  }

  // Implementation of specific methods
  static const String _keyFavorites = 'favorites';
  static const String _keyRegion = 'selected_region';

  @override
  Future<List<String>> getFavorites() async {
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  @override
  Future<void> addFavorite(String id) async {
    final list = await getFavorites();
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(_keyFavorites, list);
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    final list = await getFavorites();
    if (list.contains(id)) {
      list.remove(id);
      await prefs.setStringList(_keyFavorites, list);
    }
  }

  @override
  Future<bool> isFavorite(String id) async {
    final list = await getFavorites();
    return list.contains(id);
  }

  @override
  Future<String> getSelectedRegion() async {
    return prefs.getString(_keyRegion) ?? '전국';
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    await prefs.setString(_keyRegion, region);
  }

  @override
  Future<void> clearAll() async {
    await prefs.clear();
  }

  @override
  Future<void> clearVotes() async {
    final districts = prefs.getStringList(_keyVoteDistricts) ?? [];
    for (final district in districts) {
      await prefs.remove('$_keyVotePrefix$district');
      await prefs.remove('$_keyTimePrefix$district');
    }
    await prefs.remove(_keyVoteDistricts);
  }

  // 투표 관련 구현
  static const String _keyVotePrefix = 'vote_';
  static const String _keyTimePrefix = 'vote_time_';
  static const String _keyVoteDistricts = 'vote_districts';

  @override
  Future<void> saveVote(String district, String memberId, {int? timestamp}) async {
    await prefs.setString('$_keyVotePrefix$district', memberId);
    if (timestamp != null) {
      await prefs.setInt('$_keyTimePrefix$district', timestamp);
    }
    // 투표한 선거구 목록도 관리
    final districts = prefs.getStringList(_keyVoteDistricts) ?? [];
    if (!districts.contains(district)) {
      districts.add(district);
      await prefs.setStringList(_keyVoteDistricts, districts);
    }
    
    // 스트림 업데이트
    final allVotes = await getAllVotes();
    _votesController.add(allVotes);
  }

  @override
  Future<String?> getVote(String district) async {
    return prefs.getString('$_keyVotePrefix$district');
  }

  @override
  Future<int?> getVoteTimestamp(String district) async {
    return prefs.getInt('$_keyTimePrefix$district');
  }

  @override
  Future<Map<String, String>> getAllVotes() async {
    final districts = prefs.getStringList(_keyVoteDistricts) ?? [];
    final votes = <String, String>{};
    for (final district in districts) {
      final memberId = prefs.getString('$_keyVotePrefix$district');
      if (memberId != null) {
        votes[district] = memberId;
      }
    }
    return votes;
  }

  @override
  Future<Map<String, int>> getAllVoteTimestamps() async {
    final districts = prefs.getStringList(_keyVoteDistricts) ?? [];
    final times = <String, int>{};
    for (final district in districts) {
      final timestamp = prefs.getInt('$_keyTimePrefix$district');
      if (timestamp != null) {
        times[district] = timestamp;
      }
    }
    return times;
  }

  @override
  Future<void> removeVote(String district) async {
    await prefs.remove('$_keyVotePrefix$district');
    await prefs.remove('$_keyTimePrefix$district');
    final districts = prefs.getStringList(_keyVoteDistricts) ?? [];
    districts.remove(district);
    await prefs.setStringList(_keyVoteDistricts, districts);

    // 스트림 업데이트
    final allVotes = await getAllVotes();
    _votesController.add(allVotes);
  }
}
