import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:elecko26_new/features/map/domain/entities/election_map.dart';
import 'package:elecko26_new/features/map/domain/repositories/map_repository.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';

class MapRepositoryImpl implements MapRepository {
  @override
  Future<ElectionMapData> getElectionMapData() async {
    // 160MB 단일 파일 대신 split된 에셋 파일을 순차적으로 로드
    final candidatesList = <dynamic>[];
    for (var i = 0; i < 20; i++) {
      try {
        final String candidatesJsonString = await rootBundle.loadString(
          'data/candidates_split/candidates_$i.json',
        );
        final chunkList = json.decode(candidatesJsonString) as List<dynamic>;
        candidatesList.addAll(chunkList);
      } catch (_) {
        break; // 파일이 더 없으면 종료
      }
    }

    // 지역별 정당과 후보자 수 계산
    Map<String, Map<String, int>> regionPartyCounts = {};

    for (var candidate in candidatesList) {
      final district = candidate['district'] as String? ?? '';
      final party = candidate['party'] as String? ?? '무소속';

      // district에서 지역 추출 (예: "서울특별시장" → "서울특별시")
      String region = getParentRegion(district);

      if (region.isNotEmpty) {
        regionPartyCounts.putIfAbsent(region, () => {});
        regionPartyCounts[region]![party] =
            (regionPartyCounts[region]![party] ?? 0) + 1;
      }
    }

    // 정당별 득표율 계산
    Map<String, dynamic> regionalAverages = {};

    regionPartyCounts.forEach((region, partyCounts) {
      int totalCandidates =
          partyCounts.values.fold(0, (sum, count) => sum + count);
      Map<String, double> partyPercentages = {};

      partyCounts.forEach((party, count) {
        partyPercentages[party] = (count / totalCandidates) * 100;
      });

      regionalAverages[region] = partyPercentages;
    });

    // ElectionMapData 생성
    final mapData = ElectionMapData(
      regions: regionalAverages.entries.map((entry) {
        return RegionalPartyData.fromJson(
            entry.key, entry.value as Map<String, dynamic>);
      }).toList(),
      electionName: '2026 지방선거 현재 후보자 기반 분석',
      electionDate: DateTime.now().toIso8601String(),
    );

    return mapData;
  }
}
