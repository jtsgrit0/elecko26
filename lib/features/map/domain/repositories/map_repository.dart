import 'package:flutter_application_1/features/map/domain/entities/election_map.dart';

abstract class MapRepository {
  Future<ElectionMapData> getElectionMapData();
}