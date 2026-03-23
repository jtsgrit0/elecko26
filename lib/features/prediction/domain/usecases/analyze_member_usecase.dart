import 'package:flutter_application_1/domain/entities/analysis_result.dart';

/// 국회의원 AI 분석 UseCase
abstract class AnalyzeMemberUseCase {
  /// 특정 의원의 당선가능성 분석
  Future<AnalysisResult> analyzeMember(String memberId);
  
  /// 모든 의원의 당선가능성 분석
  Future<List<AnalysisResult>> analyzeAllMembers();
  
  /// 특정 의원의 일일 변화 분석
  Future<AnalysisResult> analyzeDailyChange(String memberId);
  
  /// 보완점 추출
  Future<List<String>> extractImprovementPoints(String memberId);
}

/// AnalyzeMemberUseCase 구현체
class AnalyzeMemberUseCaseImpl implements AnalyzeMemberUseCase {
  @override
  Future<AnalysisResult> analyzeMember(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<List<AnalysisResult>> analyzeAllMembers() async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<AnalysisResult> analyzeDailyChange(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<List<String>> extractImprovementPoints(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }
}
