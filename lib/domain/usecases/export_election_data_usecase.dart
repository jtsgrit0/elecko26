import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/entities/election_data_export.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';

/// 당선 가능성 데이터를 JSON으로 내보내는 Use Case
class ExportElectionDataUseCase {
  final MemberRepository memberRepository;
  final CalculateElectionPossibilityUseCase calculateElectionPossibilityUseCase;

  ExportElectionDataUseCase({
    required this.memberRepository,
    required this.calculateElectionPossibilityUseCase,
  });

  /// 모든 멤버의 당선 가능성 데이터를 내보내기
  Future<ElectionDataExport> call() async {
    try {
      // 모든 멤버 가져오기
      final members = await memberRepository.getAllMembers();

      // 각 멤버의 분석 결과 수집
      final memberDataList = <MemberElectionData>[];
      int totalPolls = 0;
      double totalPossibility = 0;
      final partyCount = <String, int>{};

      for (final member in members) {
        try {
          // 각 멤버의 당선 가능성 분석
          final analysis =
              await calculateElectionPossibilityUseCase.call(member.id);

          // 당선 가능성 데이터 생성
          final memberData = _createMemberElectionData(member, analysis);
          memberDataList.add(memberData);

          totalPossibility += analysis.electionPossibility;
          partyCount[member.party.isEmpty ? '무소속' : member.party] =
              (partyCount[member.party.isEmpty ? '무소속' : member.party] ??
                  0) +
              1;
        } catch (e) {
          print('Error analyzing member ${member.name}: $e');
          // 분석 실패한 멤버는 스킵
          continue;
        }
      }

      // 메타 정보 생성
      final metadata = ElectionMetadata(
        totalMembers: members.length,
        membersAnalyzed: memberDataList.length,
        averageElectionPossibility: memberDataList.isEmpty
            ? 0
            : totalPossibility / memberDataList.length,
        totalPolls: totalPolls, // 0으로 유지
        dataSourcesCount: 3, // 여론조사, 언론보도, SNS
        membersByParty: partyCount,
      );

      // 데이터 내보내기 객체 생성
      final exportData = ElectionDataExport(
        exportedAt: DateTime.now(),
        version: '2.0',
        members: memberDataList,
        metadata: metadata,
      );

      return exportData;
    } catch (e) {
      throw Exception('Failed to export election data: $e');
    }
  }

  /// 멤버 데이터 생성
  MemberElectionData _createMemberElectionData(
    Member member,
    AnalysisResult analysis,
  ) {
    // 최근 추이 데이터 (최근 30일)
    final recentTrends = analysis.dailyTrends.length > 30
        ? analysis.dailyTrends.sublist(analysis.dailyTrends.length - 30)
        : analysis.dailyTrends;

    // SNS 분석 데이터 변환
    SnsAnalysisExport? snsAnalysisExport;
    if (analysis.snsAnalysis != null) {
      final sns = analysis.snsAnalysis!;
      snsAnalysisExport = SnsAnalysisExport(
        totalMentions: sns.totalMentions,
        positiveMentions: sns.positiveMentions,
        neutralMentions: sns.neutralMentions,
        negativeMentions: sns.negativeMentions,
        sentimentScore: sns.sentimentScore,
        topMentions: sns.topMentions,
        engagementTrend: sns.engagementTrend,
      );
    }

    return MemberElectionData(
      id: member.id,
      name: member.name,
      party: member.party.isEmpty ? '무소속' : member.party,
      district: member.constituency,
      electionPossibility: analysis.electionPossibility,
      possibilityChange: analysis.possibilityChange,
      analyzedAt: DateTime.now(),
      achievementScore: analysis.achievementScore,
      activityScore: analysis.activityScore,
      policyScore: analysis.policyScore,
      publicImageScore: analysis.publicImageScore,
      pollScore: analysis.pollScore,
      polls: const [],
      snsAnalysis: snsAnalysisExport,
      pressReportsCount: 0,
      sentimentAverage: 0.0,
      recentTrends: recentTrends
          .map((trend) => DailyTrendExport(
                date: trend.date,
                possibility: trend.possibility,
              ))
          .toList(),
    );
  }
}
