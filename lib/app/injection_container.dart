import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/data/repositories/member_repository_impl.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:flutter_application_1/domain/usecases/export_election_data_usecase.dart';
import 'package:flutter_application_1/domain/usecases/update_members_with_nesdc_usecase.dart';
import 'package:flutter_application_1/data/datasources/github_datasource.dart';
import 'package:flutter_application_1/data/datasources/historical_election_data_source.dart';
import 'package:flutter_application_1/data/repositories/historical_election_repository_impl.dart';
import 'package:flutter_application_1/domain/repositories/historical_election_repository.dart';
import 'package:flutter_application_1/features/map/domain/repositories/map_repository.dart';
import 'package:flutter_application_1/features/map/data/repositories/map_repository.dart' as map_repo_impl;
import 'package:flutter_application_1/features/map/domain/usecases/get_election_map_data_usecase.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/data/datasources/local_storage_service.dart';
import 'package:flutter_application_1/data/datasources/shared_prefs_local_storage_service.dart';


final sl = GetIt.instance;

// GitHub token from environment (must be const for web support)
const String _githubToken = String.fromEnvironment(
  'GITHUB_TOKEN',
  defaultValue: '', // 기본값: 빈 문자열 (토큰이 없으면 기능 비활성화)
);

Future<void> init() async {
  if (sl.isRegistered<MemberRepository>() ||
      sl.isRegistered<GetMembersUseCase>() ||
      sl.isRegistered<MapRepository>()) {
    await sl.reset();
  }

  //! External
  try {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
    sl.registerLazySingleton<LocalStorageService>(
      () => SharedPreferencesService(sl<SharedPreferences>()),
    );
  } catch (e) {
    print('⚠️  SharedPreferences 로드 실패 (웹에서는 정상): $e');
    // 웹 환경에서는 SharedPreferences가 없을 수 있으므로 무시
  }

  //! Features - Member
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(),
  );

  sl.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithEmailUseCase>(
    SignInWithEmailUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignUpWithEmailUseCase>(
    SignUpWithEmailUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithGoogleUseCase>(
    SignInWithGoogleUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithAppleUseCase>(
    SignInWithAppleUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithFacebookUseCase>(
    SignInWithFacebookUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithKakaoUseCase>(
    SignInWithKakaoUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignOutUseCase>(
    SignOutUseCase(sl<AuthRepository>()),
  );

  // Repository
  sl.registerSingleton<MemberRepository>(MemberRepositoryImpl());
  
  // Historical election data
  sl.registerSingleton<HistoricalElectionDataSource>(
    HistoricalElectionDataSource(),
  );
  sl.registerSingleton<HistoricalElectionRepository>(
    HistoricalElectionRepositoryImpl(sl<HistoricalElectionDataSource>()),
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

  sl.registerSingleton<ToggleFavoriteUseCase>(
    ToggleFavoriteUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<CalculateElectionPossibilityUseCase>(
    CalculateElectionPossibilityUseCase(
      repository: sl<MemberRepository>(),
      historicalRepository: sl<HistoricalElectionRepository>(),
    ),
  );

  // GitHub DataSource
  sl.registerSingleton<GitHubDataSource>(
    GitHubDataSource(
      owner: 'jtsgrit0',
      repo: 'elecko26',
      token: _githubToken,
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
  
  //! Features - Map
  sl.registerSingleton<MapRepository>(
    map_repo_impl.MapRepositoryImpl(),
  );
  
  sl.registerSingleton<GetElectionMapDataUseCase>(
    GetElectionMapDataUseCase(sl<MapRepository>()),
  );
  
  //! Core
  
  //! External
}

/// CLI 도구 및 테스트를 위한 최소한의 초기화 로직
/// 플랫폼 전용 플러그인(SharedPreferences 등)에 대한 의존성을 제거합니다.
Future<void> initMinimal() async {
  if (sl.isRegistered<MemberRepository>() ||
      sl.isRegistered<GetMembersUseCase>() ||
      sl.isRegistered<MapRepository>()) {
    await sl.reset();
  }

  //! External
  try {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
    sl.registerLazySingleton<LocalStorageService>(
      () => SharedPreferencesService(sl<SharedPreferences>()),
    );
  } catch (e) {
    print('⚠️  initMinimal: SharedPreferences 로드 실패: $e');
  }

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(),
  );

  sl.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithEmailUseCase>(
    SignInWithEmailUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignUpWithEmailUseCase>(
    SignUpWithEmailUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithGoogleUseCase>(
    SignInWithGoogleUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithAppleUseCase>(
    SignInWithAppleUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithFacebookUseCase>(
    SignInWithFacebookUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignInWithKakaoUseCase>(
    SignInWithKakaoUseCase(sl<AuthRepository>()),
  );

  sl.registerSingleton<SignOutUseCase>(
    SignOutUseCase(sl<AuthRepository>()),
  );

  // Repository (SharedPreferences 의존성 없이 작동하도록 내부 로직에서 체크 필요)
  sl.registerSingleton<MemberRepository>(
    MemberRepositoryImpl(),
  );
  
  sl.registerSingleton<HistoricalElectionDataSource>(
    HistoricalElectionDataSource(),
  );
  sl.registerSingleton<HistoricalElectionRepository>(
    HistoricalElectionRepositoryImpl(sl<HistoricalElectionDataSource>()),
  );

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

  sl.registerSingleton<ToggleFavoriteUseCase>(
    ToggleFavoriteUseCase(repository: sl<MemberRepository>()),
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

  sl.registerSingleton<UpdateMembersWithNesdcDataUseCase>(
    UpdateMembersWithNesdcDataUseCase(
      memberRepository: sl<MemberRepository>(),
    ),
  );

  sl.registerSingleton<MapRepository>(
    map_repo_impl.MapRepositoryImpl(),
  );

  sl.registerSingleton<GetElectionMapDataUseCase>(
    GetElectionMapDataUseCase(sl<MapRepository>()),
  );
}
