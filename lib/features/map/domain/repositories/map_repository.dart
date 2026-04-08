import 'package:elecko26/features/map/domain/entities/election_map.dart';

abstract class MapRepository {
  Future<ElectionMapData> getElectionMapData();
}