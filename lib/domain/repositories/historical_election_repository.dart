import 'package:elecko26_new/domain/entities/historical_election.dart';

/// 역대 선거 데이터 저장소 인터페이스
abstract class HistoricalElectionRepository {
  /// 모든 역대 선거 데이터를 가져옴
  Future<List<HistoricalElection>> getAllElections();

  /// 특정 회차의 선거 데이터를 가져옴
  Future<HistoricalElection?> getElectionByNumber(int electionNumber);

  /// 특정 지역의 정당별 과거 평균 득표율을 가져옴
  Future<Map<String, double>> getRegionalPartyAverages(String region);

  /// 특정 지역의 과거 우세 정당 정보
  Future<String?> getDominantParty(String region);

  /// 2018년 제7회 지방선거 특정 지역의 정당 득표율을 가져옴
  Future<Map<String, double>> get2018RegionalPartyRates(String region);

  /// 특정 지역의 투표율/관심도 지표를 조회 (PDF 데이터 기반)
  Future<double> getVoterInterest(String region);
}
