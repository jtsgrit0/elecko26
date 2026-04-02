import 'package:flutter_application_1/features/map/domain/entities/election_map.dart';
import 'package:flutter_application_1/features/map/domain/repositories/map_repository.dart';

class GetElectionMapDataUseCase {
  final MapRepository repository;

  GetElectionMapDataUseCase(this.repository);

  Future<ElectionMapData> call() {
    return repository.getElectionMapData();
  }
}