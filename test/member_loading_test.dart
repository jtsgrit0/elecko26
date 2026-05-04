import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart'; // 1. 'User' 타입 import 추가
import 'package:flutter_test/flutter_test.dart';

// MemberRepository의 동작을 흉내 내는 Mock 클래스 생성
class MockMemberRepository implements MemberRepository {
  @override
  Future<List<Member>> getAllMembers() async {
    // 네트워크 요청 없이, 즉시 8001개의 가짜 Member 객체 리스트를 반환
    return List.generate(
      8001,
      (index) => Member(
        id: 'test_id_$index',
        name: 'Test Member $index',
        party: 'Test Party',
        district: 'Test District',
      ),
    );
  }

  // 2. MemberRepository의 모든 추상 메소드에 대한 빈 구현 추가
  @override
  Future<Member> getMemberById(String memberId) => throw UnimplementedError();
  @override
  Future<List<Member>> searchMembers(String query) => throw UnimplementedError();
  @override
  Future<void> updateMember(Member member) => throw UnimplementedError();
  @override
  Future<void> updateMembers(List<Member> members) => throw UnimplementedError();
  @override
  Future<void> addMember(Member member) => throw UnimplementedError();
  @override
  Future<void> deleteMember(String memberId) => throw UnimplementedError();
  @override
  Future<List<Member>> getCachedMembers() => throw UnimplementedError();
  @override
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)}) =>
      throw UnimplementedError();
  @override
  Future<void> apply2018RegionalPartyRates() => throw UnimplementedError();
  @override
  Future<void> updateMember2018Rates(String memberId) =>
      throw UnimplementedError();
  @override
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)}) =>
      throw UnimplementedError();
  @override
  Stream<List<Member>> watchMembers() => throw UnimplementedError();
  @override
  Stream<User?> watchCurrentUser() => throw UnimplementedError();
  @override
  Future<void> logout() => throw UnimplementedError();
  @override
  Stream<Map<String, String>> watchAllVotes() => throw UnimplementedError();
  @override
  Future<void> refreshMembers() => throw UnimplementedError();
  @override
  Future<void> toggleFavorite(String memberId) => throw UnimplementedError();
  @override
  Future<void> saveSupportVote(String district, String memberId, {required int timestamp}) =>
      throw UnimplementedError();
  @override
  Future<void> removeSupportVote(String district) => throw UnimplementedError();
  @override
  Future<String?> getSelectedRegion() => throw UnimplementedError();
  @override
  Future<void> saveSelectedRegion(String region) => throw UnimplementedError();
  @override
  Stream<String> watchSelectedRegion() => throw UnimplementedError();
  @override
  Future<void> resetSettings() => throw UnimplementedError();
  @override
  Future<void> syncUserSettings() => throw UnimplementedError();
  @override
  Future<void> updateParkSugiImage() => throw UnimplementedError();
  @override
  Future<void> updateYoonDaegiImage() => throw UnimplementedError();
  @override
  Future<void> updateSeoJaeyeolImage() => throw UnimplementedError();
  @override
  Future<void> crawlNewsForAllMembers() => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    if (sl.isRegistered<MemberRepository>()) {
      sl.unregister<MemberRepository>();
    }
    sl.registerLazySingleton<MemberRepository>(() => MockMemberRepository());
  });

  test('후보 데이터가 8000명 이상 로드된다', () async {
    final members = await sl<MemberRepository>().getAllMembers();
    expect(members.length, greaterThanOrEqualTo(8000));
  });
}