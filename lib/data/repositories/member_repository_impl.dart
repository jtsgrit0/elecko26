import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:elecko26/data/models/member_model.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/entities/poll.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:elecko26/data/datasources/nesdc_poll_data_source.dart';
import 'package:get_it/get_it.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:rxdart/rxdart.dart';

final sl = GetIt.instance;
// import 'package:flutter/foundation.dart'; // CLI 호환성을 위해 제거
const bool _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// 멤버 저장소 구현체 (데이터 레이어)
class MemberRepositoryImpl implements MemberRepository {
  final NesdcPollDataSource _nesdcPollDataSource = NesdcPollDataSource(
    localStorageService: sl<LocalStorageService>(),
  );
  bool _refreshInProgress = false;
  // 외부 크롤링 데이터 소스 (election_candidates.json) 기반 동적 로드를 위해 초기 명단은 비워둡니다.
  static final List<Member> _dummyMembers = [];
  
  // 실시간 데이터 동기화를 위한 컨트롤러
  static final BehaviorSubject<List<Member>> _membersController = 
      BehaviorSubject<List<Member>>.seeded([]);

  void _notifyListeners() {
    _membersController.add(List.from(_dummyMembers));
  }

  @override
  Future<void> addMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _dummyMembers.add(member);
    _notifyListeners();
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _dummyMembers.removeWhere((m) => m.id == memberId);
    _notifyListeners();
  }

  @override
  Future<List<Member>> getAllMembers() async {
    if (_dummyMembers.isEmpty) {
      await refreshMembers();
    }
    await Future.delayed(const Duration(milliseconds: 400));
    return _dummyMembers;
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    if (_dummyMembers.isEmpty) {
      await refreshMembers();
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _dummyMembers;
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    if (_dummyMembers.isEmpty) {
      await refreshMembers();
    }
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      return _dummyMembers.firstWhere((m) => m.id == memberId);
    } catch (e) {
      throw Exception('Member not found');
    }
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _dummyMembers
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.party.toLowerCase().contains(lowerQuery) ||
            m.district.toLowerCase().contains(lowerQuery) ||
            m.bio.toLowerCase().contains(lowerQuery) ||
            m.policies.any((p) => p.toLowerCase().contains(lowerQuery)) ||
            m.achievementsList.any((a) => a.toLowerCase().contains(lowerQuery)) ||
            m.improvementPoints.any((i) => i.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  @override
  Future<void> updateMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _dummyMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _dummyMembers[index] = member;
      _notifyListeners();
    }
  }

  @override
  Future<void> refreshMembers() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    final now = DateTime.now();
    
    try {
      final localService = sl<LocalStorageService>();
      final favoriteIds = await localService.getFavorites();

      String? candidatesJson;
      try {
        final rawUrl = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
        final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          candidatesJson = utf8.decode(response.bodyBytes);
        }
      } catch (_) {}

      if (candidatesJson == null) {
        try {
          candidatesJson = await rootBundle.loadString('data/election_candidates.json');
        } catch (_) {}
      }

      if (candidatesJson != null) {
        // [Optimization] JSON 파싱과 Member 객체 생성을 Isolate에서 수행
        final membersFromIsolate = await Isolate.run(() => _parseMembersInBackground(candidatesJson!, favoriteIds));
        
        for (var newMember in membersFromIsolate) {
          final idx = _dummyMembers.indexWhere((m) => m.name == newMember.name);
          if (idx != -1) {
            _dummyMembers[idx] = newMember.copyWith(
              polls: _dummyMembers[idx].polls,
              isFavorite: newMember.isFavorite,
            );
          } else if (!_dummyMembers.any((m) => m.id == newMember.id)) {
            _dummyMembers.add(newMember);
          }
        }
      }

      final entries = await _nesdcPollDataSource.fetchLatest();
      
      // 상세 정보 병렬 Fetch (I/O는 메인 스레드 비동기로 처리)
      final List<Future<void>> detailTasks = [];
      for (final member in _dummyMembers) {
        final regionKey = _mapDistrictToRegion(member.district);
        final matchedEntries = entries
            .where((e) => _matchesRegion(e.region, regionKey))
            .toList()
          ..sort((a, b) => b.registeredDate.compareTo(a.registeredDate));
        
        for (final entry in matchedEntries.take(5)) {
          detailTasks.add(_nesdcPollDataSource.fetchDetail(entry.sourceUrl));
        }
      }
      await Future.wait(detailTasks);

      // [Optimization] 복잡한 정규표현식 매칭 루프를 Isolate에서 한꺼번에 수행
      final List<NesdcPollDetail> collectedDetails = entries
          .map((e) => _nesdcPollDataSource.getCachedDetail(e.sourceUrl))
          .whereType<NesdcPollDetail>()
          .toList();

      final updatedMembers = await Isolate.run(() => _matchPollsInBackground(
        _dummyMembers,
        entries,
        collectedDetails,
        now,
      ));

      _dummyMembers.clear();
      _dummyMembers.addAll(updatedMembers);
      _notifyListeners();
    } catch (e, st) {
      debugPrint('[MemberRepo] UI Stutter Prevention Failed: $e\n$st');
    } finally {
      _refreshInProgress = false;
    }
  }
  }

  /// [Static Background Function] JSON 파싱 및 Member 객체 변환을 Isolate에서 수행
  static List<Member> _parseMembersInBackground(String jsonString, List<String> favoriteIds) {
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Member> members = [];
    for (var item in jsonList) {
       try {
         final m = MemberModel.fromJson(item as Map<String, dynamic>);
         members.add(m.copyWith(isFavorite: favoriteIds.contains(m.id)));
       } catch (_) {}
    }
    return members;
  }

  /// [Static Background Function] 대량의 여론조사 텍스트 매칭(Regex)을 Isolate에서 한꺼번에 수행
  static List<Member> _matchPollsInBackground(
    List<Member> members,
    List<NesdcPollEntry> entries,
    List<NesdcPollDetail> details,
    DateTime now,
  ) {
    // 빠른 조회를 위해 상세 정보를 Map으로 변환
    final detailMap = {for (var d in details) d.detailUrl: d};
    final updatedMembers = <Member>[];

    for (var member in members) {
      final regionKey = _staticMapDistrictToRegion(member.district);
      final matchedEntries = entries
          .where((e) => _staticMatchesRegion(e.region, regionKey))
          .toList()
        ..sort((a, b) => b.registeredDate.compareTo(a.registeredDate));
      
      final limitedEntries = matchedEntries.take(5).toList();
      final newPolls = <Poll>[];

      for (var entry in limitedEntries) {
        final detail = detailMap[entry.sourceUrl];
        if (detail == null) continue;

        final candidateNames = _staticCandidateNameVariants(member);
        final partyAliases = _staticPartyAliases(member.party);
        
        double? supportRate = detail.findSupportRate(candidateNames);
        var supportSource = '후보';
        if (supportRate == null) {
          supportRate = detail.findSupportRate(partyAliases);
          if (supportRate != null) supportSource = '정당';
        }

        final noteParts = [
          entry.client, entry.method, entry.sampleFrame, entry.pollName,
          if (entry.status != null) '결과등록: ${entry.status}',
          supportRate == null ? '결과 미공개' : '$supportSource 지지율 추출됨',
          if (detail.resultFileUrl != null) '결과 링크: ${detail.resultFileUrl}'
        ];

        newPolls.add(Poll(
          id: 'nesdc_${entry.registrationNo}',
          pollAgency: entry.agency,
          surveyDate: detail.surveyDate ?? entry.registeredDate,
          supportRate: supportRate,
          partyName: member.party,
          sampleSize: detail.sampleSize,
          marginOfError: detail.marginOfError,
          source: entry.sourceUrl,
          notes: noteParts.where((s) => s.isNotEmpty).join(' | '),
        ));
      }

      updatedMembers.add(member.copyWith(
        polls: _staticMergePolls(member.polls, newPolls),
        lastAnalysisDate: now,
      ));
    }
    return updatedMembers;
  }

  // Isolate 내부에서 사용하기 위한 정적 헬퍼 메서드들
  static String _staticMapDistrictToRegion(String district) {
    final normalized = district.replaceAll(' ', '');
    const regionMap = {
      '서울': '서울특별시', '부산': '부산광역시', '대구': '대구광역시', '인천': '인천광역시',
      '광주': '광주광역시', '대전': '대전광역시', '울산': '울산광역시', '세종': '세종특별자치시',
      '경기': '경기도', '강원': '강원도', '충북': '충청북도', '충남': '충청남도',
      '전북': '전북특별자치도', '전남': '전라남도', '경북': '경상북도', '경남': '경상남도', '제주': '제주특별자치도',
    };
    for (final entry in regionMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return '전국';
  }

  static bool _staticMatchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) return false;
    if (pollRegion.contains('전국') || pollRegion.contains(targetRegion)) return true;
    if (targetRegion == '전북특별자치도' && pollRegion.contains('전라북도')) return true;
    return false;
  }

  static List<String> _staticCandidateNameVariants(Member member) {
    final name = member.name.trim();
    if (name.isEmpty) return [];
    final variants = {name, name.replaceAll(' ', '')};
    if (name.length >= 2) variants.add('${name[0]} ${name.substring(1)}');
    const suffixes = ['후보', '후보자', '의원', '시장', '지사', '군수', '구청장', '위원장'];
    for (final s in suffixes) {
      variants.add('$name $s');
      variants.add('${name.replaceAll(' ', '')}$s');
    }
    for (final alias in _staticPartyAliases(member.party)) {
      variants.add('$alias $name');
      variants.add('$alias $name 후보');
    }
    return variants.toList();
  }

  static List<String> _staticPartyAliases(String party) {
    const aliasMap = {
      '더불어민주당': ['더불어민주당', '민주당', '더불어 민주당', '민주'],
      '국민의힘': ['국민의힘', '국힘'],
      '정의당': ['정의당'], '국민의당': ['국민의당'], '기본소득당': ['기본소득당'], '진보당': ['진보당'],
    };
    return aliasMap[party] ?? [party];
  }

  static List<Poll> _staticMergePolls(List<Poll> existing, List<Poll> incoming) {
    final byId = {for (var p in existing) p.id: p};
    for (final p in incoming) byId[p.id] = p;
    final merged = byId.values.toList();
    merged.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return merged;
  }
  }

  @override
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)}) {
    // 주기적인 강제 새로고침 (필요한 경우)
    final periodicRefresh = Stream.periodic(interval).asyncMap((_) async {
      await refreshMembers();
      return _dummyMembers;
    });

    // 수동 변경 스트림과 주기적 갱신 스트림 결합
    return MergeStream([
      _membersController.stream,
      periodicRefresh,
    ]).shareValueSeeded(_dummyMembers);
  }

  @override
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)}) {
    return watchAllMembers(interval: interval).map((members) {
      return members.firstWhere((m) => m.id == memberId);
    }).distinct();
  }

  List<Poll> _mergePolls(List<Poll> existing, List<Poll> incoming) {
    final byId = <String, Poll>{};
    for (final poll in existing) {
      byId[poll.id] = poll;
    }
    for (final poll in incoming) {
      byId[poll.id] = poll;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return merged;
  }

  List<String> _candidateNameVariants(Member member) {
    final name = member.name.trim();
    final variants = <String>{};
    if (name.isEmpty) {
      return [];
    }

    variants.add(name);
    variants.add(name.replaceAll(' ', ''));

    if (name.length >= 2) {
      variants.add('${name[0]} ${name.substring(1)}');
    }

    final suffixes = ['후보', '후보자', '의원', '시장', '지사', '군수', '구청장', '위원장'];
    for (final suffix in suffixes) {
      variants.add('$name $suffix');
      variants.add('${name.replaceAll(' ', '')}$suffix');
    }

    final partyAliases = _partyAliases(member.party);
    for (final alias in partyAliases) {
      variants.add('$alias $name');
      variants.add('$alias $name 후보');
    }

    return variants.toList();
  }

  List<String> _partyAliases(String party) {
    const aliasMap = {
      '더불어민주당': ['더불어민주당', '민주당', '더불어 민주당', '민주'],
      '국민의힘': ['국민의힘', '국힘'],
      '정의당': ['정의당'],
      '국민의당': ['국민의당'],
      '기본소득당': ['기본소득당'],
      '진보당': ['진보당'],
    };
    return aliasMap[party] ?? [party];
  }

  String _mapDistrictToRegion(String district) {
    final normalized = district.replaceAll(' ', '');
    const regionMap = {
      '서울': '서울특별시',
      '부산': '부산광역시',
      '대구': '대구광역시',
      '인천': '인천광역시',
      '광주': '광주광역시',
      '대전': '대전광역시',
      '울산': '울산광역시',
      '세종': '세종특별자치시',
      '경기': '경기도',
      '강원': '강원도',
      '충북': '충청북도',
      '충남': '충청남도',
      '전북': '전북특별자치도',
      '전남': '전라남도',
      '경북': '경상북도',
      '경남': '경상남도',
      '제주': '제주특별자치도',
    };

    for (final entry in regionMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return '전국';
  }

  bool _matchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) {
      return false;
    }
    if (pollRegion.contains('전국')) {
      return true;
    }
    if (pollRegion.contains(targetRegion)) {
      return true;
    }
    // 약식 표기 대응
    if (targetRegion == '전북특별자치도' && pollRegion.contains('전라북도')) {
      return true;
    }
    return false;
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    // 여러 멤버를 일괄 업데이트
    for (final member in members) {
      await updateMember(member);
    }
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    final index = _dummyMembers.indexWhere((m) => m.id == memberId);
    if (index == -1) return;

    final member = _dummyMembers[index];
    final newFavoriteStatus = !member.isFavorite;
    
    // UI 상태 반영 (낙관적)
    _dummyMembers[index] = member.copyWith(isFavorite: newFavoriteStatus);
    _notifyListeners();

    try {
      final localService = sl<LocalStorageService>();
      if (newFavoriteStatus) {
        await localService.addFavorite(memberId);
      } else {
        await localService.removeFavorite(memberId);
      }
      print('[MemberRepo] Local favorite status updated for $memberId');
    } catch (e) {
      // 실패 시 롤백
      _dummyMembers[index] = member; 
      _notifyListeners();
      print('[MemberRepo] Failed to save local favorite: $e');
      rethrow;
    }
  }

  @override
  Future<String> getSelectedRegion() async {
    final localService = sl<LocalStorageService>();
    return await localService.getSelectedRegion();
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    final localService = sl<LocalStorageService>();
    await localService.saveSelectedRegion(region);
  }

  @override
  Future<void> resetSettings() async {
    final localService = sl<LocalStorageService>();
    await localService.clearAll();
    
    // 메모리 내 즐겨찾기 상태 초기화
    for (var i = 0; i < _dummyMembers.length; i++) {
      _dummyMembers[i] = _dummyMembers[i].copyWith(isFavorite: false);
    }
    _notifyListeners();
  }

  @override
  Future<void> syncUserSettings() async {
    // 로컬 모드에서는 SharedPreferences의 최신 상태를 메모리에 반영
    await refreshMembers();
  }
}
