import 'package:elecko26_new/features/map/domain/entities/election_map.dart';

abstract class MapRepository {
  Future<ElectionMapData> getElectionMapData();
}