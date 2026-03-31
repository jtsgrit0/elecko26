import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/data/repositories/member_repository_impl.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:flutter_application_1/domain/usecases/export_election_data_usecase.dart';
import 'package:flutter_application_1/data/datasources/github_datasource.dart';
import 'package:flutter_application_1/data/datasources/historical_election_data_source.dart';
import 'package:flutter_application_1/data/repositories/historical_election_repository_impl.dart';
import 'package:flutter_application_1/domain/repositories/historical_election_repository.dart';

final sl = GetIt.instance;

// CLI 환경에서는 환경 변수에서 직접 토큰을 읽어옵니다.
final String _githubToken = String.fromEnvironment(
  'GITHUB_TOKEN',
  defaultValue: '',
);

/// CLI 도구 전용 초기화 로직
/// 플러터 프레임워크(UI, 플랫폼 플러그인)에 대한 의존성이 전혀 없습니다.
Future<void> initCli() async {
  // GetIt 초기화 (이미 등록된 경우 초기화 방지)
  if (sl.isRegistered<MemberRepository>()) {
    return;
  }

  // Repository
  sl.registerSingleton<MemberRepository>(
    MemberRepositoryImpl(),
  );
  
  sl.registerSingleton<HistoricalElectionDataSource>(
    HistoricalElectionDataSource(),
  );
  sl.registerSingleton<HistoricalElectionRepository>(
    HistoricalElectionRepositoryImpl(sl<HistoricalElectionDataSource>()),
  );

  sl.registerSingleton<CalculateElectionPossibilityUseCase>(
    CalculateElectionPossibilityUseCase(
      repository: sl<MemberRepository>(),
      historicalRepository: sl<HistoricalElectionRepository>(),
    ),
  );

  sl.registerSingleton<GitHubDataSource>(
    GitHubDataSource(
      owner: 'jtsgrit0',
      repo: 'elecko26',
      token: _githubToken,
      branch: 'main',
    ),
  );

  sl.registerSingleton<ExportElectionDataUseCase>(
    ExportElectionDataUseCase(
      memberRepository: sl<MemberRepository>(),
      calculateElectionPossibilityUseCase: sl<CalculateElectionPossibilityUseCase>(),
    ),
  );
}
