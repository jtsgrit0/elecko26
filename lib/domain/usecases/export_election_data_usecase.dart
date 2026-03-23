import 'package:flutter_application_1/domain/entities/analysis_result.dart';
import 'package:flutter_application_1/domain/entities/election_data_export.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';

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
          final analysis = await calculateElectionPossibilityUseCase.call(member.id);

          // 당선 가능성 데이터 생성
          final memberData = _createMemberElectionData(member, analysis);
          memberDataList.add(memberData);

          totalPolls += member.polls.length;
          totalPossibility += analysis.electionPossibility;
          partyCount[member.party] = (partyCount[member.party] ?? 0) + 1;
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
        totalPolls: totalPolls,
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
    // 언론 보도 감정 평균 계산
    double sentimentAverage = 0.0;
    if (member.pressReports.isNotEmpty) {
      int positiveCount = 0;
      for (final report in member.pressReports) {
        if (report.sentiment == 'positive') {
          positiveCount++;
        }
      }
      sentimentAverage = positiveCount / member.pressReports.length;
    }

    // 최근 추이 데이터 (최근 30일)
    final recentTrends = analysis.dailyTrends.length > 30
        ? analysis.dailyTrends.sublist(analysis.dailyTrends.length - 30)
        : analysis.dailyTrends;

    // 여론조사 데이터 변환
    final pollsExport = member.polls
        .map((poll) => PollDataExport(
              pollAgency: poll.pollAgency,
              surveyDate: poll.surveyDate,
              supportRate: poll.supportRate,
              sampleSize: poll.sampleSize,
              marginOfError: poll.marginOfError,
            ))
        .toList();

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
      party: member.party,
      district: member.district,
      electionPossibility: analysis.electionPossibility,
      possibilityChange: analysis.possibilityChange,
      analyzedAt: DateTime.now(),
      achievementScore: analysis.achievementScore,
      activityScore: analysis.activityScore,
      policyScore: analysis.policyScore,
      publicImageScore: analysis.publicImageScore,
      pollScore: _calculatePollScoreFromPolls(member),
      polls: pollsExport,
      snsAnalysis: snsAnalysisExport,
      pressReportsCount: member.pressReports.length,
      sentimentAverage: sentimentAverage,
      recentTrends: recentTrends
          .map((trend) => DailyTrendExport(
                date: trend.date,
                possibility: trend.possibility,
              ))
          .toList(),
    );
  }

  /// 여론조사 데이터로부터 여론 점수 계산
  double _calculatePollScoreFromPolls(Member member) {
    if (member.polls.isEmpty) {
      return 0.5; // 기본값
    }

    final validRates = member.polls
        .map((p) => p.supportRate)
        .whereType<double>()
        .toList();

    if (validRates.isEmpty) {
      return 0.5;
    }

    // NESDC 여론조사 분리
    final nesdcPolls = member.polls
        .where((p) => p.id.startsWith('nesdc_'))
        .map((p) => p.supportRate)
        .whereType<double>()
        .toList();

    final otherPolls = member.polls
        .where((p) => !p.id.startsWith('nesdc_'))
        .map((p) => p.supportRate)
        .whereType<double>()
        .toList();

    // NESDC 60%, 기타 40% 가중치
    double pollScore = 0.5;
    
    if (nesdcPolls.isNotEmpty) {
      final nesdcAvg =
          nesdcPolls.fold<double>(0, (sum, r) => sum + r) / nesdcPolls.length;
      final otherAvg = otherPolls.isEmpty
          ? 0.5
          : otherPolls.fold<double>(0, (sum, r) => sum + r) / otherPolls.length;
      pollScore = (nesdcAvg * 0.6) + (otherAvg * 0.4);
    } else if (otherPolls.isNotEmpty) {
      pollScore =
          otherPolls.fold<double>(0, (sum, r) => sum + r) / otherPolls.length;
    }

    return pollScore.clamp(0.0, 1.0);
  }
}
