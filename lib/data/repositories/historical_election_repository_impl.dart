import 'package:flutter_application_1/data/datasources/historical_election_data_source.dart';
import 'package:flutter_application_1/domain/entities/historical_election.dart';
import 'package:flutter_application_1/domain/repositories/historical_election_repository.dart';

/// 역대 선거 데이터 저장소 구현체
class HistoricalElectionRepositoryImpl implements HistoricalElectionRepository {
  final HistoricalElectionDataSource _dataSource;

  HistoricalElectionRepositoryImpl(this._dataSource);

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
          combined.putIfAbsent(entry.key, () => []);
          combined[entry.key]!.add(entry.value);
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
}
