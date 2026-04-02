import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/map/domain/entities/election_map.dart';

abstract class MapRepository {
  Future<ElectionMapData> getElectionMapData();
}

class MapRepositoryImpl implements MapRepository {
  @override
  Future<ElectionMapData> getElectionMapData() async {
    // historical_election_5th.json 파일 로드
    final jsonString = await rootBundle.loadString('data/historical_election_5th.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    return ElectionMapData.fromJson(jsonData);
  }
}