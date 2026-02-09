import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/data/repositories/member_repository_impl.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:flutter_application_1/domain/usecases/export_election_data_usecase.dart';
import 'package:flutter_application_1/domain/usecases/update_members_with_nesdc_usecase.dart';
import 'package:flutter_application_1/data/datasources/github_datasource.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Member
  // Repository
  sl.registerSingleton<MemberRepository>(
    MemberRepositoryImpl(),
  );
  
  // Use cases
  sl.registerSingleton<GetMembersUseCase>(
    GetMembersUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<SearchMembersUseCase>(
    SearchMembersUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<GetMemberByIdUseCase>(
    GetMemberByIdUseCase(repository: sl<MemberRepository>()),
  );

  sl.registerSingleton<WatchMembersUseCase>(
    WatchMembersUseCase(repository: sl<MemberRepository>()),
  );

  sl.registerSingleton<WatchMemberByIdUseCase>(
    WatchMemberByIdUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<CalculateElectionPossibilityUseCase>(
    CalculateElectionPossibilityUseCase(repository: sl<MemberRepository>()),
  );

  // GitHub DataSource (환경 변수에서 token 읽기)
  final githubToken = String.fromEnvironment(
    'GITHUB_TOKEN',
    defaultValue: '', // 기본값: 빈 문자열 (토큰이 없으면 기능 비활성화)
  );
  
  sl.registerSingleton<GitHubDataSource>(
    GitHubDataSource(
      owner: 'jtsgrit0',
      repo: 'elecko26',
      token: githubToken,
      branch: 'main',
    ),
  );

  // Export Use Case
  sl.registerSingleton<ExportElectionDataUseCase>(
    ExportElectionDataUseCase(
      memberRepository: sl<MemberRepository>(),
      calculateElectionPossibilityUseCase: sl<CalculateElectionPossibilityUseCase>(),
    ),
  );

  // NESDC Update Use Case
  sl.registerSingleton<UpdateMembersWithNesdcDataUseCase>(
    UpdateMembersWithNesdcDataUseCase(
      memberRepository: sl<MemberRepository>(),
    ),
  );
  
  //! Core
  
  //! External
}
