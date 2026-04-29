import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:elecko26_new/features/map/domain/entities/election_map.dart';
import 'package:elecko26_new/features/map/domain/repositories/map_repository.dart';
import 'package:elecko26_new/core/utils/utility_functions.dart';

class MapRepositoryImpl implements MapRepository {
  ElectionMapData? _cachedData;

  @override
  Future<ElectionMapData> getElectionMapData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    // 임시 데이터: 실제 데이터가 준비될 때까지 사용할 지역별 정당 지지율
    const Map<String, Map<String, double>> mockRegionalPartySupport = {
      '서울특별시': {'더불어민주당': 48.5, '국민의힘': 40.2, '정의당': 4.8, '기타': 6.5},
      '부산광역시': {'더불어민주당': 38.1, '국민의힘': 52.4, '정의당': 3.5, '기타': 6.0},
      '대구광역시': {'더불어민주당': 25.0, '국민의힘': 65.8, '정의당': 2.2, '기타': 7.0},
      '인천광역시': {'더불어민주당': 49.8, '국민의힘': 41.0, '정의당': 4.2, '기타': 5.0},
      '광주광역시': {'더불어민주당': 75.5, '국민의힘': 15.2, '정의당': 5.3, '기타': 4.0},
      '대전광역시': {'더불어민주당': 51.2, '국민의힘': 39.8, '정의당': 4.5, '기타': 4.5},
      '울산광역시': {'더불어민주당': 40.1, '국민의힘': 48.9, '정의당': 4.0, '기타': 7.0},
      '세종특별자치시': {'더불어민주당': 55.3, '국민의힘': 35.1, '정의당': 5.6, '기타': 4.0},
      '경기도': {'더불어민주당': 52.8, '국민의힘': 38.5, '정의당': 4.7, '기타': 4.0},
      '강원특별자치도': {'더불어민주당': 42.0, '국민의힘': 48.5, '정의당': 3.5, '기타': 6.0},
      '충청북도': {'더불어민주당': 47.9, '국민의힘': 44.3, '정의당': 3.8, '기타': 4.0},
      '충청남도': {'더불어민주당': 48.5, '국민의힘': 43.1, '정의당': 3.4, '기타': 5.0},
      '전북특별자치도': {'더불어민주당': 70.2, '국민의힘': 18.9, '정의당': 6.9, '기타': 4.0},
      '전라남도': {'더불어민주당': 72.8, '국민의힘': 16.7, '정의당': 6.5, '기타': 4.0},
      '경상북도': {'더불어민주당': 22.5, '국민의힘': 68.3, '정의당': 2.2, '기타': 7.0},
      '경상남도': {'더불어민주당': 39.8, '국민의힘': 51.0, '정의당': 3.2, '기타': 6.0},
      '제주특별자치도': {'더불어민주당': 50.1, '국민의힘': 39.5, '정의당': 5.4, '기타': 5.0},
    };

    // ElectionMapData 생성
    _cachedData = ElectionMapData(
      regions: mockRegionalPartySupport.entries.map((entry) {
        return RegionalPartyData.fromJson(entry.key, entry.value);
      }).toList(),
      electionName: '2026 지방선거 예측 지지율 (임시)',
      electionDate: DateTime.now().toIso8601String(),
    );

    return _cachedData!;
  }
}
