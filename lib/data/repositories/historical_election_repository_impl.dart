import 'package:elecko26/data/datasources/historical_election_data_source.dart';
import 'package:elecko26/domain/entities/historical_election.dart';
import 'package:elecko26/domain/repositories/historical_election_repository.dart';

/// 역대 선거 데이터 저장소 구현체
/// 정당명 변경 이력을 고려하여 4개 선거의 데이터를 통합합니다.
class HistoricalElectionRepositoryImpl implements HistoricalElectionRepository {
  final HistoricalElectionDataSource _dataSource;

  HistoricalElectionRepositoryImpl(this._dataSource);

  /// 보수/진보 정당 계보 정규화 맵
  /// 한나라당 → 새누리당 → 자유한국당 → 미래통합당 → 국민의힘
  /// 민주당 → 새정치민주연합 → 더불어민주당
  static const _partyNormalization = {
    '한나라당': '국민의힘',
    '새누리당': '국민의힘',
    '자유한국당': '국민의힘',
    '미래통합당': '국민의힘',
    '민주당': '더불어민주당',
    '새정치민주연합': '더불어민주당',
    '열린우리당': '더불어민주당',
    '민주평화당': '더불어민주당',
  };

  String _normalizeParty(String party) {
    return _partyNormalization[party] ?? party;
  }

  @override
  Future<List<HistoricalElection>> getAllElections() {
    return _dataSource.loadAll();
  }

  @override
  Future<HistoricalElection?> getElectionByNumber(int electionNumber) async {
    final elections = await _dataSource.loadAll();
    try {
      return elections.firstWhere((e) => e.electionNumber == electionNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, double>> getRegionalPartyAverages(String region) async {
    final elections = await _dataSource.loadAll();
    final combined = <String, List<double>>{};

    for (final election in elections) {
      final regionData = election.regionalAverages[region];
      if (regionData != null) {
        for (final entry in regionData.entries) {
          // 정당명을 현재 이름으로 정규화
          final normalizedParty = _normalizeParty(entry.key);
          combined.putIfAbsent(normalizedParty, () => []);
          combined[normalizedParty]!.add(entry.value);
        }
      }
    }

    return combined.map((party, rates) =>
        MapEntry(party, rates.reduce((a, b) => a + b) / rates.length));
  }

  @override
  Future<String?> getDominantParty(String region) async {
    final averages = await getRegionalPartyAverages(region);
    if (averages.isEmpty) return null;

    String? dominant;
    double maxRate = 0;
    for (final entry in averages.entries) {
      if (entry.key != '무소속' && entry.value > maxRate) {
        maxRate = entry.value;
        dominant = entry.key;
      }
    }
    return dominant;
  }

  @override
  Future<double> getVoterInterest(String region) async {
    final pdfData = await _dataSource.loadPdfData();
    
    double totalInterest = 0;
    int count = 0;

    for (final fileData in pdfData.values) {
      if (fileData is Map<String, dynamic>) {
        // 지역명이 포함되어 있는지 확인 (예: "서울", "종로구" 등)
        for (final entry in fileData.entries) {
          if (region.contains(entry.key) || entry.key.contains(region)) {
            if (entry.value is num) {
              totalInterest += (entry.value as num).toDouble();
              count++;
            }
          }
        }
      }
    }

    if (count == 0) return 0.5; // 기본값: 중간 수준
    return totalInterest / count;
  }
}
