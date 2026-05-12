import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';

class MemberRepositoryImpl implements MemberRepository {
  List<Member> _members = [];
  Completer<void>? _initializer;
  SharedPreferences? _prefs;

  // 데이터 변경을 알리기 위한 StreamController
  final _membersController = StreamController<List<Member>>.broadcast();

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _initialize() async {
    if (_initializer != null) {
      return _initializer!.future;
    }
    _initializer = Completer<void>();

    try {
      final String response =
          await rootBundle.loadString('api/members_enriched.json');

      // 백그라운드에서 JSON 파싱 및 객체 변환 수행
      _members = await compute(_parseMembers, response);

      // 초기 데이터 로드 후 스트림에 추가
      _membersController.add(_members);
      _initializer!.complete();
    } catch (e) {
      _initializer!.completeError(e);
      rethrow;
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
    return _prefs?.getString('selectedRegion');
  }

  @override
  Future<void> removeSupportVote(String district) async {}

  @override
  Future<void> resetSettings() async {}

  @override
  Future<void> saveSelectedRegion(String region) async {
    await _initPrefs();
    await _prefs?.setString('selectedRegion', region);
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
    return Stream.value('');
  }

  @override
  Future<void> logout() async {
    await _initPrefs();
    await _prefs?.remove('selectedRegion');
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
