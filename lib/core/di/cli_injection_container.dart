import 'dart:convert';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/domain/usecases/export_election_data_usecase.dart';
import 'package:elecko26_new/data/datasources/github_datasource.dart';
import 'package:elecko26_new/data/datasources/historical_election_data_source.dart';
import 'package:elecko26_new/data/repositories/historical_election_repository_impl.dart';
import 'package:elecko26_new/domain/repositories/historical_election_repository.dart';
import 'package:http/http.dart' as http;

final sl = GetIt.instance;

/// CLI 전용 MemberRepository - Flutter 프레임워크 의존성 없음
class CliMemberRepository implements MemberRepository {
  final List<Member> _members = [];
  final Set<String> _favorites = {};
  String _selectedRegion = '전국';
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    // 로컬 파일에서 즐겨찾기 로드
    try {
      final favFile = File('data/favorites.json');
      if (await favFile.exists()) {
        final data = jsonDecode(await favFile.readAsString()) as List;
        _favorites.addAll(data.map((e) => e.toString()));
      }
    } catch (_) {}

    // GitHub Raw에서 후보자 데이터 로드
    String? jsonStr;
    try {
      final url =
          'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
      final resp =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        jsonStr = utf8.decode(resp.bodyBytes);
      }
    } catch (_) {}

    // fallback: 로컬 파일
    if (jsonStr == null) {
      try {
        final localFile = File('data/election_candidates.json');
        if (await localFile.exists()) {
          jsonStr = await localFile.readAsString();
        }
      } catch (_) {}
    }

    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr!) as List;
        for (final item in list) {
          final member = MemberModel.fromJson(item as Map<String, dynamic>);
          _members
              .add(member.copyWith(isFavorite: _favorites.contains(member.id)));
        }
      } catch (_) {}
    }
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await _ensureLoaded();
    return List.unmodifiable(_members);
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    await _ensureLoaded();
    return List.unmodifiable(_members);
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await _ensureLoaded();
    try {
      return _members.firstWhere((m) => m.id == memberId);
    } catch (_) {
      throw Exception('Member not found');
    }
  }

  @override
  Future<void> refreshMembers() async => await _ensureLoaded();

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) async* {
    await _ensureLoaded();
    yield List.unmodifiable(_members);
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) async* {
    await _ensureLoaded();
    try {
      yield _members.firstWhere((m) => m.id == memberId);
    } catch (_) {
      throw Exception('Not found');
    }
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    await _ensureLoaded();
    if (_favorites.contains(memberId)) {
      _favorites.remove(memberId);
    } else {
      _favorites.add(memberId);
    }
    final idx = _members.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      _members[idx] =
          _members[idx].copyWith(isFavorite: _favorites.contains(memberId));
    }
    // 로컬 파일에 저장
    try {
      final favFile = File('data/favorites.json');
      await favFile.writeAsString(jsonEncode(_favorites.toList()));
    } catch (_) {}
  }

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) async {}

  @override
  Future<void> removeSupportVote(String district) async {}

  @override
  Future<String?> getSelectedRegion() async => _selectedRegion;
  @override
  Future<void> saveSelectedRegion(String region) async =>
      _selectedRegion = region;
  @override
  Stream<String> watchSelectedRegion() async* {
    yield _selectedRegion;
  }

  @override
  Future<void> resetSettings() async {
    _favorites.clear();
    _selectedRegion = '전국';
    try {
      await File('data/favorites.json').delete();
    } catch (_) {}
  }

  @override
  Future<void> syncUserSettings() async => await _ensureLoaded();

  @override
  Future<void> addMember(Member member) async {}
  @override
  Future<void> deleteMember(String memberId) async {}
  @override
  Future<void> updateMember(Member member) async {}
  @override
  Future<void> updateMembers(List<Member> members) async {}
  @override
  Future<List<Member>> searchMembers(String query) async {
    await _ensureLoaded();
    final q = query.toLowerCase();
    return _members
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.party.toLowerCase().contains(q) ||
            m.district.toLowerCase().contains(q))
        .toList();
  }
}

/// CLI 도구 전용 초기화 로직
/// 플러터 프레임워크(UI, 플랫폼 플러그인)에 대한 의존성이 전혀 없습니다.
Future<void> initCli() async {
  if (sl.isRegistered<MemberRepository>()) {
    return;
  }

  sl.registerSingleton<MemberRepository>(CliMemberRepository());

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
      token: Platform.environment['GITHUB_TOKEN'] ?? '',
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
}
