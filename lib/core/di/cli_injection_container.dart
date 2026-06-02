import 'dart:convert';
import 'dart:io';

import 'package:elecko26_new/data/datasources/github_datasource.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/export_election_data_usecase.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

class CliMemberRepository implements MemberRepository {
  List<Member> _members = [];
  bool _loaded = false;
  String _selectedRegion = '전국';
  final Set<String> _favorites = {};

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final candidates = <File>[
      File('assets/data/candidates_2026.json'),
      File('data/election_candidates.json'),
      File('api/members.json'),
    ];

    File? sourceFile;
    for (final candidate in candidates) {
      if (await candidate.exists()) {
        sourceFile = candidate;
        break;
      }
    }

    if (sourceFile == null) {
      _members = [];
      _loaded = true;
      return;
    }

    final raw = await sourceFile.readAsString();
    final decoded = jsonDecode(raw);
    final list = decoded is List
        ? decoded
        : decoded is Map<String, dynamic> && decoded['members'] is List
            ? decoded['members'] as List
            : <dynamic>[];

    _members = list
        .whereType<Map>()
        .map((item) => MemberModel.fromJson(Map<String, dynamic>.from(item)))
        .map((member) => member.copyWith(
              isFavorite: _favorites.contains(member.id),
            ))
        .toList();

    _loaded = true;
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await _ensureLoaded();
    return List.unmodifiable(_members);
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await _ensureLoaded();
    return _members.firstWhere((member) => member.id == memberId);
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await _ensureLoaded();
    final q = query.toLowerCase();
    return _members
        .where((member) =>
            member.name.toLowerCase().contains(q) ||
            member.party.toLowerCase().contains(q) ||
            member.constituency.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<void> updateMember(Member member) async {
    await _ensureLoaded();
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
    }
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    await _ensureLoaded();
    _members = List<Member>.from(members);
  }

  @override
  Future<void> addMember(Member member) async {
    await _ensureLoaded();
    _members.add(member);
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _ensureLoaded();
    _members.removeWhere((member) => member.id == memberId);
  }

  @override
  Future<void> clearAllMembers() async {
    _members.clear();
    _loaded = true;
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    await _ensureLoaded();
    return List.unmodifiable(_members);
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) async* {
    yield await getAllMembers();
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) async* {
    yield await getMemberById(memberId);
  }

  @override
  Stream<List<Member>> watchMembers() {
    return Stream.fromFuture(getAllMembers());
  }

  @override
  Future<void> apply2018RegionalPartyRates() async {}

  @override
  Future<void> updateMember2018Rates(String memberId) async {}

  @override
  Stream<User?> watchCurrentUser() => Stream.value(null);

  @override
  Future<void> logout() async {}

  @override
  Stream<Map<String, String>> watchAllVotes() => Stream.value({});

  @override
  Future<void> refreshMembers() async {
    _loaded = false;
    await _ensureLoaded();
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    await _ensureLoaded();
    if (_favorites.contains(memberId)) {
      _favorites.remove(memberId);
    } else {
      _favorites.add(memberId);
    }

    final index = _members.indexWhere((member) => member.id == memberId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(
        isFavorite: _favorites.contains(memberId),
      );
    }
  }

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) async {}

  @override
  Future<void> removeSupportVote(String district) async {}

  @override
  Future<String?> getSelectedRegion() async => _selectedRegion;

  @override
  Future<void> saveSelectedRegion(String region) async {
    _selectedRegion = region;
  }

  @override
  Stream<String> watchSelectedRegion() => Stream.value(_selectedRegion);

  @override
  Future<void> resetSettings() async {
    _favorites.clear();
    _selectedRegion = '전국';
  }

  @override
  Future<void> syncUserSettings() async {}

  @override
  Future<void> updateParkSugiImage() async {}

  @override
  Future<void> updateYoonDaegiImage() async {}

  @override
  Future<void> updateSeoJaeyeolImage() async {}

  @override
  Future<void> crawlNewsForAllMembers() async {}
}

Future<void> initCli() async {
  if (sl.isRegistered<MemberRepository>()) {
    return;
  }

  sl.registerLazySingleton<MemberRepository>(() => CliMemberRepository());
  sl.registerLazySingleton<CalculateElectionPossibilityUseCase>(
    () => CalculateElectionPossibilityUseCase(repository: sl<MemberRepository>()),
  );
  sl.registerLazySingleton<GitHubDataSource>(() {
    return GitHubDataSource(
      owner: 'jtsgrit0',
      repo: 'elecko26',
      token: Platform.environment['GITHUB_TOKEN'] ?? '',
      branch: 'main',
    );
  });
  sl.registerLazySingleton<ExportElectionDataUseCase>(() {
    return ExportElectionDataUseCase(
      memberRepository: sl<MemberRepository>(),
      calculateElectionPossibilityUseCase:
          sl<CalculateElectionPossibilityUseCase>(),
    );
  });
}

Future<void> init() => initCli();