import 'package:flutter_application_1/domain/entities/analysis_result.dart';

/// 분석 결과 Repository 추상 클래스
abstract class AnalysisRepository {
  /// 의원 분석
  Future<AnalysisResult> analyzeElectionPossibility(String memberId);
  
  /// 모든 의원 분석
  Future<List<AnalysisResult>> analyzeAllMembers();
  
  /// 일일 분석 결과 조회
  Future<AnalysisResult> getDailyAnalysis(String memberId, DateTime date);
  
  /// 분석 결과 저장
  Future<void> saveAnalysisResult(AnalysisResult result);
  
  /// 분석 이력 조회
  Future<List<AnalysisResult>> getAnalysisHistory(String memberId);
  
  /// 보완점 추출
  Future<List<String>> extractImprovementPoints(String memberId);
}
