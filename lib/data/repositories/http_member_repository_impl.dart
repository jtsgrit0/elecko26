import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';

class HttpMemberRepositoryImpl implements MemberRepository {
  final String _baseUrl = 'members.json';

  // --- MemberRepository 인터페이스의 모든 메소드 구현 ---

  @override
  Future<List<Member>> getAllMembers() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        // UTF-8로 명시적으로 디코딩
        final List<dynamic> jsonData =
            json.decode(utf8.decode(response.bodyBytes));
        final List<Member> members =
            jsonData.map((data) => MemberModel.fromJson(data)).toList();
        return members;
      } else {
        throw Exception(
            'API로부터 멤버 정보를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('멤버 정보를 불러오는 중 오류 발생: $e');
    }
  }

  @override
  Future<Member> getMemberById(String memberId) {
    // API에 단일 멤버를 가져오는 기능이 추가되어야 함
    throw UnimplementedError('getMemberById는 아직 구현되지 않았습니다.');
  }

  @override
  Future<List<Member>> searchMembers(String query) {
    throw UnimplementedError('searchMembers는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> updateMember(Member member) {
    throw UnimplementedError('updateMember는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> updateMembers(List<Member> members) {
    throw UnimplementedError('updateMembers는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> addMember(Member member) {
    throw UnimplementedError('addMember는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> deleteMember(String memberId) {
    throw UnimplementedError('deleteMember는 아직 구현되지 않았습니다.');
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    // HTTP 구현에서는 매번 네트워크에서 가져옵니다.
    return getAllMembers();
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) {
    // HTTP에서는 실시간 감지가 어려우므로, Future를 Stream으로 변환하여 한 번만 데이터를 제공합니다.
    return Stream.fromFuture(getAllMembers());
  }

  @override
  Future<void> apply2018RegionalPartyRates() {
    throw UnimplementedError('apply2018RegionalPartyRates는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> updateMember2018Rates(String memberId) {
    throw UnimplementedError('updateMember2018Rates는 아직 구현되지 않았습니다.');
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) {
    return Stream.fromFuture(getMemberById(memberId));
  }

  @override
  Stream<List<Member>> watchMembers() {
    return Stream.fromFuture(getAllMembers());
  }

  @override
  Stream<User?> watchCurrentUser() {
    // HTTP 기반 인증/사용자 관리가 필요합니다.
    return Stream.value(null); // 현재는 로그인된 사용자가 없다고 가정
  }

  @override
  Future<void> logout() {
    throw UnimplementedError('logout은 아직 구현되지 않았습니다.');
  }

  @override
  Stream<Map<String, String>> watchAllVotes() {
    // 투표 기능은 별도의 API 엔드포인트가 필요합니다.
    return Stream.value({});
  }

  @override
  Future<void> refreshMembers() {
    // 캐시를 사용하지 않으므로 이 메소드는 아무것도 하지 않습니다.
    return Future.value();
  }

  @override
  Future<void> toggleFavorite(String memberId) {
    throw UnimplementedError('toggleFavorite는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) {
    throw UnimplementedError('saveSupportVote는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> removeSupportVote(String district) {
    throw UnimplementedError('removeSupportVote는 아직 구현되지 않았습니다.');
  }

  @override
  Future<String?> getSelectedRegion() {
    // 로컬 저장소(SharedPreferences 등)를 사용하는 것이 적합합니다.
    throw UnimplementedError('getSelectedRegion은 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> saveSelectedRegion(String region) {
    // 로컬 저장소(SharedPreferences 등)를 사용하는 것이 적합합니다.
    throw UnimplementedError('saveSelectedRegion은 아직 구현되지 않았습니다.');
  }

  @override
  Stream<String> watchSelectedRegion() {
    // 로컬 저장소(SharedPreferences 등)의 변경을 감지해야 합니다.
    return Stream.empty();
  }

  @override
  Future<void> resetSettings() {
    throw UnimplementedError('resetSettings는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> syncUserSettings() {
    throw UnimplementedError('syncUserSettings는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> updateParkSugiImage() {
    throw UnimplementedError('updateParkSugiImage는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> updateYoonDaegiImage() {
    throw UnimplementedError('updateYoonDaegiImage는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> updateSeoJaeyeolImage() {
    throw UnimplementedError('updateSeoJaeyeolImage는 아직 구현되지 않았습니다.');
  }

  @override
  Future<void> crawlNewsForAllMembers() {
    throw UnimplementedError('crawlNewsForAllMembers는 아직 구현되지 않았습니다.');
  }
}
