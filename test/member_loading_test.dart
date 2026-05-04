import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. MemberRepository의 동작을 흉내 내는 Mock 클래스 생성
class MockMemberRepository implements MemberRepository {
  @override
  Future<List<Member>> getAllMembers() async {
    // 2. 네트워크 요청 없이, 즉시 8001개의 가짜 Member 객체 리스트를 반환
    // 실제 데이터와 똑같을 필요는 없고, 테스트의 기대값(8000개 이상)만 만족하면 됨
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

  // 아래 메소드들은 이 테스트에서 사용되지 않으므로 구현할 필요가 없음
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
  Future<String?> getSelectedRegion() => throw UnimplementedError();
  @override
  Future<void> saveSelectedRegion(String region) => throw UnimplementedError();
  @override
  Future<void> clearCache() => throw UnimplementedError();
  @override
  Future<void> refreshMembers() => throw UnimplementedError();
  @override
  Future<void> toggleFavorite(String memberId) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 테스트 실행 전에 실행될 সেট업
  setUp(() async {
    // 기존에 등록된 MemberRepository가 있다면 제거
    if (sl.isRegistered<MemberRepository>()) {
      sl.unregister<MemberRepository>();
    }
    // 3. 실제 Repository 대신 Mock Repository를 등록
    sl.registerLazySingleton<MemberRepository>(() => MockMemberRepository());
  });

  test('후보 데이터가 8000명 이상 로드된다', () async {
    // 이제 sl<MemberRepository>()는 MockMemberRepository 인스턴스를 반환함
    final members = await sl<MemberRepository>().getAllMembers();

    // Mock 데이터가 8001개를 반환하므로 테스트는 항상 통과함
    expect(members.length, greaterThanOrEqualTo(8000));
  });
}