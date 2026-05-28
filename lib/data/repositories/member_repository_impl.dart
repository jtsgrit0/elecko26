import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';
import 'package:rxdart/rxdart.dart'; // rxdart 임포트

class MemberRepositoryImpl implements MemberRepository {
  List<Member> _members = [];
  Completer<void>? _initializer;
  SharedPreferences? _prefs;

  // 데이터 변경을 알리기 위한 StreamController
  final _membersController = StreamController<List<Member>>.broadcast();
  // 선택된 지역 변경을 알리기 위한 BehaviorSubject
  final _selectedRegionController = BehaviorSubject<String>();

  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      // SharedPreferences에서 초기 지역 값을 읽어와 BehaviorSubject 초기화
      final initialRegion = _prefs?.getString('selectedRegion') ?? '전국';
      if (!_selectedRegionController.isClosed &&
          _selectedRegionController.valueOrNull != initialRegion) {
        _selectedRegionController.add(initialRegion);
      }
    }
  }

  Future<void> _initialize() async {
    if (_initializer != null) {
      return _initializer!.future;
    }
    _initializer = Completer<void>();

    try {
      // assets/elec_pdf/ 내 PDF 파일명에서 유효 지역 키워드 집합 추출 (이중 안전 필터)
      final Set<String> validRegionKeywords = await _loadPdfRegionKeywords();
      debugPrint('[MemberRepo] elec_pdf 유효 지역 키워드: ${validRegionKeywords.length}개');

      // 항상 PDF에서 추출한 assets/data/election_candidates.json 파일을 우선 로드
      final jsonStr =
          await rootBundle.loadString('assets/data/election_candidates.json');
      debugPrint('[MemberRepo] PDF에서 추출한 election_candidates.json 로드 성공');

      // 백그라운드에서 JSON 파싱 및 객체 변환 수행
      final allMembers = await compute(_parseMembers, jsonStr);

      // 이중 안전 필터: elec_pdf에 PDF가 없는 지역 후보 완전 차단
      if (validRegionKeywords.isNotEmpty) {
        _members = allMembers.where((m) {
          final district = (m.district + ' ' + m.constituency).toLowerCase();
          return validRegionKeywords.any((kw) => district.contains(kw));
        }).toList();
        debugPrint('[MemberRepo] 이중 필터 후 후보: ${_members.length}명 (전체 ${allMembers.length}명 중)');
      } else {
        _members = allMembers;
        debugPrint('[MemberRepo] 필터 키워드 없음 - 전체 로드: ${_members.length}명');
      }

      // 초기 데이터 로드 후 스트림에 추가
      _membersController.add(_members);
      _initializer!.complete();
    } catch (e) {
      _initializer!.completeError(e);
      rethrow;
    }
  }

  /// assets/elec_pdf/ 하위 PDF 파일명에서 지역 키워드 Set을 추출합니다.
  /// 예: "[구·시·군의회의원선거][강원특별자치도][강릉시].pdf"
  ///   → {'강원특별자치도', '강릉시', '강원', '강릉'}
  Future<Set<String>> _loadPdfRegionKeywords() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final pdfAssets = manifest.listAssets()
          .where((key) => key.startsWith('assets/elec_pdf/') && key.endsWith('.pdf'))
          .toList();

      final Set<String> keywords = {};
      final bracketRegex = RegExp(r'\[([^\]]+)\]');

      for (final assetKey in pdfAssets) {
        final filename = assetKey.split('/').last;
        for (final match in bracketRegex.allMatches(filename)) {
          final part = match.group(1) ?? '';
          // 선거 종류 구분자는 제외 (지역명만 수집)
          if (part.contains('선거') || part.contains('제9회') || part.contains('후보자') || part.contains('명부')) continue;
          // 원본 추가
          keywords.add(part.toLowerCase());
          // 도/시 등 행정 단위 앞 2글자도 추가 (부분 매칭용)
          if (part.length >= 2) keywords.add(part.substring(0, 2).toLowerCase());
          // 복합 선거구 (예: "군산시김제시부안군") 분리
          final subParts = part.split(RegExp(r'(?<=[시군구도])'));
          for (final sub in subParts) {
            if (sub.length >= 2) keywords.add(sub.toLowerCase());
          }
        }
      }
      return keywords;
    } catch (e) {
      debugPrint('[MemberRepo] PDF 지역 키워드 로드 실패: $e');
      return {};
    }
  }

  // 최상위 함수 또는 정적 함수여야 compute에서 사용 가능
  static List<Member> _parseMembers(String response) {
    final data = json.decode(response) as List;
    return data
        .map((json) => MemberModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await _initialize();
    return List.from(_members);
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await _initialize();
    return _members.firstWhere((member) => member.id == memberId);
  }

  @override
  Future<void> addMember(Member member) async {
    await _initialize();
    _members.add(member);
    _membersController.add(List.from(_members)); // 변경 알림
  }

  @override
  Future<void> updateMember(Member member) async {
    await _initialize();
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
      _membersController.add(List.from(_members)); // 변경 알림
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _initialize();
    _members.removeWhere((member) => member.id == memberId);
    _membersController.add(List.from(_members)); // 변경 알림
  }

  @override
  Future<void> clearAllMembers() async {
    await _initialize();
    _members.clear();
    _membersController.add(List.from(_members)); // 변경 알림
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await _initialize();
    return _members.where((member) {
      return member.name.toLowerCase().contains(query.toLowerCase()) ||
          member.party.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<void> refreshMembers() async {
    _initializer = null;
    await _initialize();
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) {
    // 이제 실제 스트림을 반환합니다.
    return _membersController.stream;
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) {
    // 특정 멤버의 변경을 감지하려면 더 복잡한 로직이 필요하지만,
    // 여기서는 전체 목록 스트림을 기반으로 필터링합니다.
    return _membersController.stream.map((members) {
      return members.firstWhere((member) => member.id == memberId,
          orElse: () => throw Exception('Member not found'));
    });
  }

  @override
  Future<void> crawlNewsForAllMembers() async {
    // This is a local implementation, so we do nothing here.
    return;
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    await _initialize();
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      final member = _members[index];
      final updatedMember = member.copyWith(isFavorite: !member.isFavorite);
      _members[index] = updatedMember;
      _membersController.add(List.from(_members)); // 변경 알림
    }
  }

  @override
  Stream<List<Member>> watchMembers() {
    // watchAllMembers와 동일한 스트림을 사용합니다.
    return _membersController.stream;
  }

  // ... 나머지 메소드들은 변경 없음 ...

  @override
  Future<void> apply2018RegionalPartyRates() async {}

  @override
  Future<List<Member>> getCachedMembers() async {
    return List.from(_members);
  }

  @override
  Future<String?> getSelectedRegion() async {
    await _initPrefs();
    return _selectedRegionController.valueOrNull;
  }

  @override
  Future<void> removeSupportVote(String district) async {}

  @override
  Future<void> resetSettings() async {}

  @override
  Future<void> saveSelectedRegion(String region) async {
    await _initPrefs();
    await _prefs?.setString('selectedRegion', region);
    if (!_selectedRegionController.isClosed) {
      _selectedRegionController.add(region); // 스트림에 새로운 지역 추가
    }
  }

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) async {}

  @override
  Future<void> syncUserSettings() async {}

  @override
  Future<void> updateMember2018Rates(String memberId) async {}

  @override
  Future<void> updateMembers(List<Member> members) async {
    _members = members;
    _membersController.add(List.from(_members)); // 변경 알림
  }

  @override
  Stream<Map<String, String>> watchAllVotes() {
    return Stream.value({});
  }

  @override
  Stream<String> watchSelectedRegion() {
    // _initPrefs가 호출되어 _selectedRegionController가 초기화되도록 보장
    _initPrefs();
    return _selectedRegionController.stream;
  }

  @override
  Future<void> logout() async {
    await _initPrefs();
    await _prefs?.remove('selectedRegion');
    if (!_selectedRegionController.isClosed) {
      _selectedRegionController.add('전국'); // 로그아웃 시 지역을 '전국'으로 초기화
    }
  }

  // 리소스 해제를 위한 dispose 메서드 추가
  void dispose() {
    _membersController.close();
    _selectedRegionController.close();
  }

  @override
  Stream<User?> watchCurrentUser() {
    return Stream.value(null);
  }

  @override
  Future<void> updateParkSugiImage() async {}

  @override
  Future<void> updateSeoJaeyeolImage() async {}

  @override
  Future<void> updateYoonDaegiImage() async {}
}
