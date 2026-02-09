import 'package:flutter_application_1/domain/entities/analysis_result.dart';
import 'package:flutter_application_1/domain/repositories/analysis_repository.dart';

/// 의원 분석 UseCase
class AnalyzeMemberUseCase {
  final AnalysisRepository repository;

  AnalyzeMemberUseCase({required this.repository});

  Future<AnalysisResult> call(String memberId) async {
    return await repository.analyzeElectionPossibility(memberId);
  }
}

/// 모든 의원 분석 UseCase
class AnalyzeAllMembersUseCase {
  final AnalysisRepository repository;

  AnalyzeAllMembersUseCase({required this.repository});

  Future<List<AnalysisResult>> call() async {
    return await repository.analyzeAllMembers();
  }
}

/// 일일 분석 변화 UseCase
class GetDailyAnalysisUseCase {
  final AnalysisRepository repository;

  GetDailyAnalysisUseCase({required this.repository});

  Future<AnalysisResult> call(String memberId, DateTime date) async {
    return await repository.getDailyAnalysis(memberId, date);
  }
}

/// 분석 이력 조회 UseCase
class GetAnalysisHistoryUseCase {
  final AnalysisRepository repository;

  GetAnalysisHistoryUseCase({required this.repository});

  Future<List<AnalysisResult>> call(String memberId) async {
    return await repository.getAnalysisHistory(memberId);
  }
}

/// 보완점 추출 UseCase
class ExtractImprovementPointsUseCase {
  final AnalysisRepository repository;

  ExtractImprovementPointsUseCase({required this.repository});

  Future<List<String>> call(String memberId) async {
    return await repository.extractImprovementPoints(memberId);
  }
}
