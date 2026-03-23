import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/entities/poll.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/nesdc_pdf_extractor.dart';

/// NESDC PDF 데이터로 멤버 여론조사 정보 업데이트
class UpdateMembersWithNesdcDataUseCase {
  final MemberRepository memberRepository;

  UpdateMembersWithNesdcDataUseCase({
    required this.memberRepository,
  });

  /// NESDC PDF 텍스트에서 추출한 데이터로 멤버 업데이트
  Future<List<Member>> updateWithNesdcPdf(String pdfText) async {
    try {
      // 1. PDF에서 지지율 추출
      final supportRates = NesdcPdfExtractor.extractSupportRates(pdfText);
      
      // 2. PDF에서 메타 정보 추출
      final metadata = NesdcPdfExtractor.extractPollMetadata(pdfText);
      
      // 3. 모든 멤버 가져오기
      final allMembers = await memberRepository.getAllMembers();
      
      // 4. 멤버명으로 지지율 매칭
      final matchedRates = NesdcPdfExtractor.matchWithMembers(
        supportRates,
        allMembers.map((m) => m.name).toList(),
      );
      
      // 5. 각 멤버의 polls에 NESDC 데이터 추가
      final updatedMembers = <Member>[];
      
      for (final member in allMembers) {
        if (matchedRates.containsKey(member.name)) {
          // NESDC 지지율이 있는 멤버
          final updatedMember = _addNesdcPoll(
            member,
            matchedRates[member.name]!,
            metadata,
          );
          updatedMembers.add(updatedMember);
        } else {
          updatedMembers.add(member);
        }
      }
      
      // 6. 업데이트된 멤버 저장
      await memberRepository.updateMembers(updatedMembers);
      
      return updatedMembers;
    } catch (e) {
      throw Exception('Failed to update members with NESDC data: $e');
    }
  }

  /// 멤버에 NESDC Poll 추가
  Member _addNesdcPoll(
    Member member,
    double supportRate,
    Map<String, dynamic> metadata,
  ) {
    // NESDC poll 생성
    final nesdcPoll = Poll(
      id: 'nesdc_${DateTime.now().millisecondsSinceEpoch}',
      pollAgency: metadata['pollAgency'] ?? 'NESDC',
      surveyDate: metadata['surveyDate'] ?? DateTime.now(),
      supportRate: supportRate,
      partyName: member.party,
      sampleSize: (metadata['sampleSize'] as int?),
      marginOfError: (metadata['marginOfError'] as double?),
      source: 'https://www.nesdc.go.kr',
      notes: 'NESDC 공식 여론조사',
    );

    // 기존 polls에 추가 (중복 제거: 같은 날짜의 NESDC 데이터는 업데이트)
    final existingPolls = member.polls
        .where((p) => !(p.id.startsWith('nesdc_') && 
            p.surveyDate.year == nesdcPoll.surveyDate.year &&
            p.surveyDate.month == nesdcPoll.surveyDate.month &&
            p.surveyDate.day == nesdcPoll.surveyDate.day))
        .toList();

    final updatedPolls = [nesdcPoll, ...existingPolls];

    // 새로운 Member 객체 생성 (불변성 유지)
    return Member(
      id: member.id,
      name: member.name,
      party: member.party,
      district: member.district,
      imageUrl: member.imageUrl,
      bio: member.bio,
      electionDate: member.electionDate,
      term: member.term,
      policies: member.policies,
      achievementsList: member.achievementsList,
      actions: member.actions,
      pressReports: member.pressReports,
      polls: updatedPolls,
      electionPossibility: member.electionPossibility,
      lastAnalysisDate: DateTime.now(),
      improvementPoints: member.improvementPoints,
    );
  }

  /// 특정 정당의 NESDC 데이터 추출
  /// (선거구 세분화가 필요한 경우 사용)
  Map<String, List<String>> extractPartyData(String pdfText) {
    return NesdcPdfExtractor.extractByParty(pdfText);
  }

  /// 지원 가능한 NESDC 형식
  /// 
  /// 1. 선출직별 형식:
  ///    "국회의원" 또는 "지방의원" 섹션별로 정렬
  /// 
  /// 2. 정당별 형식:
  ///    "민주당", "국민의힘" 등 정당 섹션으로 정렬
  /// 
  /// 3. 선거구별 형식:
  ///    각 지역/선거구별로 후보자와 지지율 표시
  /// 
  /// 예상 데이터 구조:
  /// ```
  /// 국회의원 여론조사
  /// [조사기간] 2026년 2월 2일 ~ 2월 5일
  /// [표본크기] N = 1,500
  /// [오차한계] ±2.5%
  /// 
  /// ≪민주당≫
  /// 1. 김철수  45.2%
  /// 2. 이영희  42.1%
  /// 
  /// ≪국민의힘≫
  /// 1. 박민준  38.5%
  /// 2. 최정수  35.2%
  /// ```
}
