import 'package:elecko26_new/core/config/app_config.dart';
import 'package:elecko26_new/data/repositories/firestore_member_repository_impl.dart';
import 'package:get_it/get_it.dart';
import 'package:elecko26_new/data/repositories/member_repository_impl.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/export_election_data_usecase.dart';
import 'package:elecko26_new/domain/usecases/update_members_with_nesdc_usecase.dart';
import 'package:elecko26_new/domain/usecases/update_2018_party_support_from_pdf_usecase.dart';
import 'package:elecko26_new/data/datasources/github_datasource.dart';
import 'package:elecko26_new/data/datasources/historical_election_data_source.dart';
import 'package:elecko26_new/data/repositories/historical_election_repository_impl.dart';
import 'package:elecko26_new/domain/repositories/historical_election_repository.dart';
import 'package:elecko26_new/features/map/domain/repositories/map_repository.dart';
import 'package:elecko26_new/features/map/data/repositories/map_repository.dart'
    as map_repo_impl;
import 'package:elecko26_new/features/map/domain/usecases/get_election_map_data_usecase.dart';
import 'package:elecko26_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:elecko26_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:elecko26_new/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart';
import 'package:elecko26_new/data/datasources/shared_prefs_local_storage_service.dart';
import 'package:elecko26_new/features/voting/data/repositories/poll_repository_impl.dart';
import 'package:elecko26_new/features/voting/domain/repositories/poll_repository.dart';
import 'package:elecko26_new/features/voting/domain/usecases/poll_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

final sl = GetIt.instance;

const String _githubToken = String.fromEnvironment(
  'GITHUB_TOKEN',
  defaultValue: '',
);

Future<void> init() async {
  if (sl.isRegistered<MemberRepository>()) {
    await sl.reset();
  }

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<LocalStorageService>(
    () => SharedPreferencesService(sl<SharedPreferences>()),
  );

  _registerAll();
}

Future<void> initMinimal() async {
  debugPrint('[DI] Initializing Minimal DI...');
  if (sl.isRegistered<MemberRepository>()) {
    await sl.reset();
  }

  //! External
  try {
    debugPrint('[DI] Loading SharedPreferences...');
    final sharedPreferences = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('[DI] SharedPreferences timeout, using fallback');
        throw Exception('Timeout');
      },
    );
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
    sl.registerLazySingleton<LocalStorageService>(
      () => SharedPreferencesService(sl<SharedPreferences>()),
    );
  } catch (e) {
    debugPrint('[DI] SharedPreferences Load failed, registering fallback: $e');
    sl.registerLazySingleton<LocalStorageService>(
        () => InMemoryLocalStorageService());
  }

  _registerAll();
  debugPrint('[DI] Minimal DI Initialization Complete');
}

void _registerAll() {
  //! Features
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  // Auth UseCases
  sl.registerSingleton<GetCurrentUserUseCase>(
      GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignInWithEmailUseCase>(
      SignInWithEmailUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignUpWithEmailUseCase>(
      SignUpWithEmailUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignInWithGoogleUseCase>(
      SignInWithGoogleUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignInWithAppleUseCase>(
      SignInWithAppleUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignInWithFacebookUseCase>(
      SignInWithFacebookUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignInWithKakaoUseCase>(
      SignInWithKakaoUseCase(sl<AuthRepository>()));
  sl.registerSingleton<SignOutUseCase>(SignOutUseCase(sl<AuthRepository>()));

  // Repository
  if (AppConfig.enableFirebase) {
    debugPrint('[DI] Firebase 활성화됨 - FirestoreMemberRepositoryImpl 등록');
    sl.registerSingleton<MemberRepository>(FirestoreMemberRepositoryImpl());
  } else {
    debugPrint('[DI] Firebase 비활성화됨 - MemberRepositoryImpl 등록');
    sl.registerSingleton<MemberRepository>(MemberRepositoryImpl());
  }

  sl.registerSingleton<HistoricalElectionDataSource>(
      HistoricalElectionDataSource());
  sl.registerSingleton<HistoricalElectionRepository>(
    HistoricalElectionRepositoryImpl(sl<HistoricalElectionDataSource>()),
  );

  sl.registerSingleton<PollRepository>(PollRepositoryImpl());

  // UseCases
  sl.registerSingleton<GetMembersUseCase>(
      GetMembersUseCase(repository: sl<MemberRepository>()));
  sl.registerSingleton<SearchMembersUseCase>(
      SearchMembersUseCase(repository: sl<MemberRepository>()));
  sl.registerSingleton<GetMemberByIdUseCase>(
      GetMemberByIdUseCase(repository: sl<MemberRepository>()));
  sl.registerSingleton<WatchMembersUseCase>(
      WatchMembersUseCase(repository: sl<MemberRepository>()));
  sl.registerSingleton<WatchMemberByIdUseCase>(
      WatchMemberByIdUseCase(repository: sl<MemberRepository>()));
  sl.registerSingleton<ToggleFavoriteUseCase>(
      ToggleFavoriteUseCase(repository: sl<MemberRepository>()));

  sl.registerSingleton<GetPollsUseCase>(GetPollsUseCase(sl<PollRepository>()));
  sl.registerSingleton<CreatePollUseCase>(
      CreatePollUseCase(sl<PollRepository>()));
  sl.registerSingleton<UpdatePollStatusUseCase>(
      UpdatePollStatusUseCase(sl<PollRepository>()));

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
      calculateElectionPossibilityUseCase:
          sl<CalculateElectionPossibilityUseCase>(),
    ),
  );

  sl.registerSingleton<UpdateMembersWithNesdcDataUseCase>(
    UpdateMembersWithNesdcDataUseCase(
      memberRepository: sl<MemberRepository>(),
    ),
  );
  sl.registerSingleton<Update2018PartySupportFromPdfUseCase>(
    Update2018PartySupportFromPdfUseCase(repository: sl<MemberRepository>()),
  );

  sl.registerSingleton<MapRepository>(map_repo_impl.MapRepositoryImpl());
  sl.registerSingleton<GetElectionMapDataUseCase>(
      GetElectionMapDataUseCase(sl<MapRepository>()));
}

/// Fallback storage for cases where SharedPreferences is unavailable (e.g. CLI tools or failing Web)
class InMemoryLocalStorageService implements LocalStorageService {
  final Map<String, dynamic> _data = {};
  final _votesController = BehaviorSubject<Map<String, String>>();

  InMemoryLocalStorageService() {
    _votesController.add({});
  }

  @override
  Stream<Map<String, String>> watchAllVotes() => _votesController.stream;

  @override
  String? getString(String key) => _data[key] as String?;
  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Future<List<String>> getFavorites() async =>
      (_data['favorites'] as List<String>?) ?? [];
  @override
  Future<void> addFavorite(String id) async {
    final list = await getFavorites();
    if (!list.contains(id)) list.add(id);
    await setStringList('favorites', list);
  }

  @override
  Future<void> removeFavorite(String id) async {
    final list = await getFavorites();
    list.remove(id);
    await setStringList('favorites', list);
  }

  @override
  Future<bool> isFavorite(String id) async =>
      (await getFavorites()).contains(id);
  @override
  Future<String> getSelectedRegion() async =>
      _data['selected_region'] as String? ?? 'ì „êµ­';
  @override
  Future<void> saveSelectedRegion(String region) async =>
      await setString('selected_region', region);
  @override
  Future<void> clearAll() async => _data.clear();
  @override
  Future<void> clearVotes() async {
    final districts = _data[_keyVoteDistricts] as List<String>? ?? [];
    for (final district in districts) {
      _data.remove('$_keyVotePrefix$district');
      _data.remove('$_keyTimePrefix$district');
    }
    _data.remove(_keyVoteDistricts);
  }

  // íˆ¬í‘œ ê´€ë ¨ êµ¬í˜„ (In-Memory)
  static const String _keyVotePrefix = 'vote_';
  static const String _keyTimePrefix = 'vote_time_';
  static const String _keyVoteDistricts = 'vote_districts';

  @override
  Future<void> saveVote(String district, String memberId,
      {int? timestamp}) async {
    _data['$_keyVotePrefix$district'] = memberId;
    if (timestamp != null) {
      _data['$_keyTimePrefix$district'] = timestamp;
    }
    final districts =
        List<String>.from(_data[_keyVoteDistricts] as List<dynamic>? ?? []);
    if (!districts.contains(district)) {
      districts.add(district);
      _data[_keyVoteDistricts] = districts;
    }

    _votesController.add(await getAllVotes());
  }

  @override
  Future<String?> getVote(String district) async {
    return _data['$_keyVotePrefix$district'] as String?;
  }

  @override
  Future<int?> getVoteTimestamp(String district) async {
    return _data['$_keyTimePrefix$district'] as int?;
  }

  @override
  Future<Map<String, String>> getAllVotes() async {
    final districts = _data[_keyVoteDistricts] as List<String>? ?? [];
    final votes = <String, String>{};
    for (final district in districts) {
      final memberId = _data['$_keyVotePrefix$district'] as String?;
      if (memberId != null) {
        votes[district] = memberId;
      }
    }
    return votes;
  }

  @override
  Future<Map<String, int>> getAllVoteTimestamps() async {
    final districts = _data[_keyVoteDistricts] as List<String>? ?? [];
    final times = <String, int>{};
    for (final district in districts) {
      final timestamp = _data['$_keyTimePrefix$district'] as int?;
      if (timestamp != null) {
        times[district] = timestamp;
      }
    }
    return times;
  }

  @override
  Future<void> removeVote(String district) async {
    _data.remove('$_keyVotePrefix$district');
    _data.remove('$_keyTimePrefix$district');
    final List<String> districts =
        List<String>.from(_data[_keyVoteDistricts] as List<dynamic>? ?? []);
    districts.remove(district);
    _data[_keyVoteDistricts] = districts;

    _votesController.add(await getAllVotes());
  }
}
