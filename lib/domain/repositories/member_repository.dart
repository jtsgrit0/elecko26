import 'package:elecko26/domain/entities/member.dart';

/// 회원 Repository 추상 클래스
abstract class MemberRepository {
  /// 모든 의원 조회
  Future<List<Member>> getAllMembers();
  
  /// 특정 의원 조회
  Future<Member> getMemberById(String memberId);
  
  /// 의원 검색
  Future<List<Member>> searchMembers(String query);
  
  /// 의원 정보 업데이트
  Future<void> updateMember(Member member);
  
  /// 여러 의원 정보 일괄 업데이트
  Future<void> updateMembers(List<Member> members);
  
  /// 의원 추가
  Future<void> addMember(Member member);
  
  /// 의원 삭제
  Future<void> deleteMember(String memberId);
  
  /// 캐시된 의원 데이터 조회
  Future<List<Member>> getCachedMembers();

  /// 일정 주기로 의원 데이터 갱신 스트림 제공
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)});

  /// 특정 의원 데이터 갱신 스트림 제공
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)});

  /// 외부 데이터 소스에서 최신 데이터 갱신
  Future<void> refreshMembers();

  /// 즐겨찾기 상태 토글
  Future<void> toggleFavorite(String memberId);

  /// 사용자 지역 설정을 읽고 저장하는 메서드입니다.
  Future<String> getSelectedRegion();
  Future<void> saveSelectedRegion(String region);
  
  /// 지역 설정 변경을 실시간으로 감지하는 스트림을 제공합니다.
  Stream<String> watchSelectedRegion();

  Future<void> resetSettings();

  /// 사용자 설정을 클라우드와 동기화합니다.
  Future<void> syncUserSettings();
}
