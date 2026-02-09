import 'package:flutter_application_1/domain/entities/member.dart';

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
}
