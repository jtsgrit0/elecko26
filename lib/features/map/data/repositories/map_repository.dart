import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/map/domain/entities/election_map.dart';
import 'package:flutter_application_1/features/map/domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  @override
  Future<ElectionMapData> getElectionMapData() async {
    // 현재 후보자 데이터 로드
    final candidatesJsonString = await rootBundle.loadString('data/election_candidates.json');
    final candidatesList = json.decode(candidatesJsonString) as List<dynamic>;

    // 지역별 정당과 후보자 수 계산
    Map<String, Map<String, int>> regionPartyCounts = {};
    
    for (var candidate in candidatesList) {
      final district = candidate['district'] as String? ?? '';
      final party = candidate['party'] as String? ?? '무소속';
      
      // district에서 지역 추출 (예: "서울특별시장" → "서울특별시")
      String region = _extractRegion(district);
      
      if (region.isNotEmpty) {
        regionPartyCounts.putIfAbsent(region, () => {});
        regionPartyCounts[region]![party] = (regionPartyCounts[region]![party] ?? 0) + 1;
      }
    }

    // 정당별 득표율 계산
    Map<String, dynamic> regionalAverages = {};
    
    regionPartyCounts.forEach((region, partyCounts) {
      int totalCandidates = partyCounts.values.fold(0, (sum, count) => sum + count);
      Map<String, double> partyPercentages = {};
      
      partyCounts.forEach((party, count) {
        partyPercentages[party] = (count / totalCandidates) * 100;
      });
      
      regionalAverages[region] = partyPercentages;
    });

    // ElectionMapData 생성
    final mapData = ElectionMapData(
      regions: regionalAverages.entries.map((entry) {
        return RegionalPartyData.fromJson(entry.key, entry.value as Map<String, dynamic>);
      }).toList(),
      electionName: '2026 지방선거 현재 후보자 기반 분석',
      electionDate: DateTime.now().toIso8601String(),
    );

    return mapData;
  }

  /// district에서 시/도 지역명 추출
  String _extractRegion(String district) {
    // "서울특별시장" → "서울특별시"
    // "경기도지사" → "경기도"
    // "부산광역시장" → "부산광역시"
    
    final regionMap = {
      '서울': '서울특별시',
      '부산': '부산광역시',
      '대구': '대구광역시',
      '인천': '인천광역시',
      '광주': '광주광역시',
      '대전': '대전광역시',
      '울산': '울산광역시',
      '세종': '세종특별자치시',
      '경기': '경기도',
      '강원': '강원도',
      '충청북': '충청북도',
      '충청남': '충청남도',
      '전라북': '전라북도',
      '전라남': '전라남도',
      '경상북': '경상북도',
      '경상남': '경상남도',
      '제주': '제주특별자치도',
      '김해': '경상남도', // 시/군 정보는 시/도로 분류
    };

    for (var key in regionMap.keys) {
      if (district.contains(key)) {
        return regionMap[key]!;
      }
    }

    return '';
  }
}