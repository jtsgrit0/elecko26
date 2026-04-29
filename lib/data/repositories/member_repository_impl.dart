import 'dart:convert';
import 'dart:isolate';
import 'package:elecko26_new/core/utils/utility_functions.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart';
import 'package:elecko26_new/data/datasources/nesdc_poll_data_source.dart';
import 'package:elecko26_new/data/datasources/profile_image_resolver.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/repositories/historical_election_repository.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/usecases/possibility_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

final sl = GetIt.instance;

/// 멤버 저장소 구현체 (데이터 레이어)
class MemberRepositoryImpl implements MemberRepository {
  final LocalStorageService _localStorage = sl<LocalStorageService>();
  final NesdcPollDataSource _nesdcPollDataSource = NesdcPollDataSource();

  late final ProfileImageResolver _profileImageResolver = ProfileImageResolver(
    localStorageService: sl<LocalStorageService>(),
  );
  bool _refreshInProgress = false;
  static final List<Member> _dummyMembers = [];

  static final BehaviorSubject<List<Member>> _membersController =
      BehaviorSubject<List<Member>>.seeded([]);

  static final BehaviorSubject<String> _regionController =
      BehaviorSubject<String>();

  void _notifyListeners() {
    _membersController.add(List.from(_dummyMembers));
  }

  @override
  Future<void> addMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _dummyMembers.add(member);
    _notifyListeners();
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _dummyMembers.removeWhere((m) => m.id == memberId);
    _notifyListeners();
  }

  @override
  Future<List<Member>> getAllMembers() async {
    if (_dummyMembers.isEmpty) {
      await refreshMembers();
    }
    return _dummyMembers;
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    return _dummyMembers;
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    try {
      return _dummyMembers.firstWhere((m) => m.id == memberId);
    } catch (e) {
      throw Exception('Member not found');
    }
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    final lowerQuery = query.toLowerCase();
    return _dummyMembers
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.party.toLowerCase().contains(lowerQuery) ||
            m.district.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<void> updateMember(Member member) async {
    final index = _dummyMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _dummyMembers[index] = member;
      _notifyListeners();
    }
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    for (final member in members) {
      await updateMember(member);
    }
  }

  Future<String?> _fetchCandidatesFromLocalAssets() async {
    try {
      final List<Future<String>> futures = [];
      for (int i = 0; i <= 8; i++) {
        final String assetPath = 'data/candidates_split/candidates_$i.json';
        futures.add(rootBundle.loadString(assetPath));
      }
      final List<String> jsonStrings = await Future.wait(futures);
      final List<Map<String, dynamic>> allCandidates = [];
      for (final jsonString in jsonStrings) {
        final List<dynamic> candidates = json.decode(jsonString);
        allCandidates.addAll(candidates.cast<Map<String, dynamic>>());
      }
      return json.encode(allCandidates);
    } catch (e) {
      debugPrint('Error loading candidate assets: $e');
      return null;
    }
  }

  @override
  Future<void> refreshMembers() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    final now = DateTime.now();

    try {
      final localService = sl<LocalStorageService>();
      final favoriteIds = await localService.getFavorites();

      // 1. 로컬 스토리지에 캐시된 가공 데이터가 있는지 먼저 확인 (매우 빠름)
      if (_dummyMembers.isEmpty) {
        final cachedData = _localStorage.getString('cached_processed_members');
        if (cachedData != null) {
          try {
            final List<dynamic> decoded = json.decode(cachedData);
            final cachedMembers = decoded
                .map((item) =>
                    MemberModel.fromJson(item as Map<String, dynamic>))
                .toList();
            _dummyMembers.addAll(cachedMembers);
            _notifyListeners();
            debugPrint('[MemberRepo] Loaded from persistent cache');
          } catch (e) {
            debugPrint('[MemberRepo] Persistent cache parse error: $e');
          }
        }
      }

      String? candidatesJson = await _fetchCandidatesFromLocalAssets();

      if (candidatesJson != null) {
        final membersFromIsolate = kIsWeb
            ? _parseMembersInBackground(candidatesJson, favoriteIds)
            : await Isolate.run(
                () => _parseMembersInBackground(candidatesJson!, favoriteIds));

        for (var newMember in membersFromIsolate) {
          final idx = _dummyMembers.indexWhere((m) => m.name == newMember.name);
          if (idx != -1) {
            _dummyMembers[idx] = newMember.copyWith(
              polls: _dummyMembers[idx].polls,
              isFavorite: newMember.isFavorite,
            );
          } else if (!_dummyMembers.any((m) => m.id == newMember.id)) {
            _dummyMembers.add(newMember);
          }
        }
      }

      // 프로필 이미지가 비어있는 항목은 백그라운드로 조용히 보강
      _resolveMissingProfileImagesInBackground();

      final entries = await _nesdcPollDataSource.fetchLatest();

      // 최적화: 유효한 지역들 추출 (중복 제거)
      final uniqueRegions = _dummyMembers
          .map((m) => _staticMapDistrictToRegion(m.district))
          .toSet();

      // 최적화: 유효한 지역에 해당하는 최근 여론조사 100건만 상세 정보 가져오기
      final relevantEntries = entries
          .where((e) =>
              uniqueRegions.any((r) => _staticMatchesRegion(e.region, r)))
          .take(100)
          .toList();

      final List<Future<void>> detailTasks = [];
      for (final entry in relevantEntries) {
        detailTasks.add(_nesdcPollDataSource.fetchDetail(entry.sourceUrl));
      }
      await Future.wait(detailTasks);

      final List<NesdcPollDetail> collectedDetails = relevantEntries
          .map((e) => _nesdcPollDataSource.getCachedDetail(e.sourceUrl))
          .whereType<NesdcPollDetail>()
          .toList();

      final updatedMembers = kIsWeb
          ? _matchPollsInBackground(
              List.from(_dummyMembers), relevantEntries, collectedDetails, now)
          : await Isolate.run(() => _matchPollsInBackground(
                List.from(_dummyMembers),
                relevantEntries,
                collectedDetails,
                now,
              ));

      // 당선 가능성 최신화 (상세 페이지와 동일 로직 적용)
      final historicalRepo = sl<HistoricalElectionRepository>();
      final List<Member> finalMembers = [];

      for (final member in updatedMembers) {
        double historicalBaseSupport = 0.5;
        double voterInterest = 0.5;
        try {
          final region = _staticMapDistrictToRegion(member.district);
          final averages =
              await historicalRepo.getRegionalPartyAverages(region);
          voterInterest = await historicalRepo.getVoterInterest(region);
          final partyRate = averages[member.party];
          if (partyRate != null) {
            historicalBaseSupport = (partyRate / 100.0).clamp(0.0, 1.0);
          }
        } catch (_) {}

        final scores = PossibilityCalculator.calculateMultiFactorScores(
          member: member,
          historicalBaseSupport: historicalBaseSupport,
          voterInterest: voterInterest,
        );

        finalMembers.add(member.copyWith(
          electionPossibility: scores['overall']!,
        ));
      }

      _dummyMembers.clear();
      _dummyMembers.addAll(finalMembers);
      _notifyListeners();

      // 가공된 최종 데이터를 로컬 스토리지에 캐시 (다음 기동 시 즉시 로딩용)
      try {
        final jsonToCache = json.encode(
            _dummyMembers.map((m) => (m as MemberModel).toJson()).toList());
        await _localStorage.setString('cached_processed_members', jsonToCache);
      } catch (e) {
        debugPrint('[MemberRepo] Error saving persistent cache: $e');
      }
    } catch (e, st) {
      debugPrint('[MemberRepo] Refresh Failed: $e\n$st');
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> _resolveMissingProfileImagesInBackground() async {
    final candidates = _dummyMembers
        .where((m) =>
            m.imageUrl.trim().isEmpty &&
            _profileImageResolver.shouldAttempt(m.id))
        .take(15)
        .toList();
    if (candidates.isEmpty) return;

    try {
      bool changed = false;
      for (final member in candidates) {
        final cached = _profileImageResolver.getCachedUrl(member.id);
        if (cached != null && cached.isNotEmpty) {
          final idx = _dummyMembers.indexWhere((m) => m.id == member.id);
          if (idx != -1 && _dummyMembers[idx].imageUrl.trim().isEmpty) {
            _dummyMembers[idx] = _dummyMembers[idx].copyWith(imageUrl: cached);
            changed = true;
          }
          continue;
        }

        final resolved =
            await _profileImageResolver.resolveImageUrlByName(member.name);
        if (resolved == null || resolved.trim().isEmpty) {
          await _profileImageResolver.cacheNegative(member.id);
          continue;
        }

        await _profileImageResolver.cacheUrl(member.id, resolved);
        final idx = _dummyMembers.indexWhere((m) => m.id == member.id);
        if (idx != -1 && _dummyMembers[idx].imageUrl.trim().isEmpty) {
          _dummyMembers[idx] = _dummyMembers[idx].copyWith(imageUrl: resolved);
          changed = true;
        }
      }

      if (changed) {
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('[MemberRepo] Profile image resolve failed: $e');
    }
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) {
    final periodicRefresh = Stream.periodic(interval).asyncMap((_) async {
      await refreshMembers();
      return _dummyMembers;
    });
    return MergeStream([
      _membersController.stream,
      periodicRefresh,
    ]).shareValueSeeded(_dummyMembers);
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) {
    final cachedIndex = _dummyMembers.indexWhere((m) => m.id == memberId);
    final Member? cachedMember =
        cachedIndex != -1 ? _dummyMembers[cachedIndex] : null;

    final stream = watchAllMembers(interval: interval)
        .where((members) => members.any((m) => m.id == memberId))
        .map((members) => members.firstWhere((m) => m.id == memberId));
    // .distinct() 제거: isFavorite 변경 시에도 스트림 전파되도록

    return cachedMember != null ? stream.startWith(cachedMember) : stream;
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    final index = _dummyMembers.indexWhere((m) => m.id == memberId);
    if (index == -1) return;

    final member = _dummyMembers[index];
    final newFavoriteStatus = !member.isFavorite;

    _dummyMembers[index] = member.copyWith(isFavorite: newFavoriteStatus);
    _notifyListeners();

    try {
      final localService = sl<LocalStorageService>();
      if (newFavoriteStatus) {
        await localService.addFavorite(memberId);
      } else {
        await localService.removeFavorite(memberId);
      }
    } catch (e) {
      _dummyMembers[index] = member;
      _notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) async {
    final localService = sl<LocalStorageService>();
    await localService.saveVote(district, memberId, timestamp: timestamp);
  }

  @override
  Future<void> removeSupportVote(String district) async {
    final localService = sl<LocalStorageService>();
    await localService.removeVote(district);
  }

  @override
  Future<String?> getSelectedRegion() async {
    if (_regionController.hasValue) {
      return _regionController.value;
    }
    final localService = sl<LocalStorageService>();
    final region = await localService.getSelectedRegion();
    if (region != null) {
      _regionController.add(region);
    }
    return region;
  }

  @override
  Stream<Map<String, String>> watchAllVotes() => _localStorage.watchAllVotes();

  @override
  Future<void> saveSelectedRegion(String region) async {
    final localService = sl<LocalStorageService>();
    await localService.saveSelectedRegion(region);
    _regionController.add(region);
  }

  @override
  Stream<String> watchSelectedRegion() {
    // 초기 호출 시 현재 저장된 값을 스트림에 흘려보냄
    getSelectedRegion();
    return _regionController.stream;
  }

  @override
  Future<void> resetSettings() async {
    final localService = sl<LocalStorageService>();
    await localService.clearAll();
    for (var i = 0; i < _dummyMembers.length; i++) {
      _dummyMembers[i] = _dummyMembers[i].copyWith(isFavorite: false);
    }
    _regionController.add('전국');
    _notifyListeners();
  }

  @override
  Future<void> syncUserSettings() async {
    await refreshMembers();
  }

  // --- Static Helpers for Isolate ---

  static List<Member> _parseMembersInBackground(
      String jsonString, List<String> favoriteIds) {
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Member> members = [];
    for (var item in jsonList) {
      try {
        final m = MemberModel.fromJson(item as Map<String, dynamic>);
        members.add(m.copyWith(isFavorite: favoriteIds.contains(m.id)));
      } catch (_) {}
    }
    return members;
  }

  static List<Member> _matchPollsInBackground(
    List<Member> members,
    List<NesdcPollEntry> entries,
    List<NesdcPollDetail> details,
    DateTime now,
  ) {
    final detailMap = {for (var d in details) d.detailUrl: d};
    final updatedMembers = <Member>[];

    for (var member in members) {
      final regionKey = _staticMapDistrictToRegion(member.district);
      final matchedEntries = entries
          .where((e) => _staticMatchesRegion(e.region, regionKey))
          .toList()
        ..sort((a, b) => b.registeredDate.compareTo(a.registeredDate));

      final limitedEntries = matchedEntries.take(5).toList();
      final newPolls = <Poll>[];

      for (var entry in limitedEntries) {
        final detail = detailMap[entry.sourceUrl];
        if (detail == null) continue;

        final candidateNames = _staticCandidateNameVariants(member);
        final partyAliases = _staticPartyAliases(member.party);

        double? supportRate = detail.findSupportRate(candidateNames);
        supportRate ??= detail.findSupportRate(partyAliases);

        newPolls.add(Poll(
          id: 'nesdc_${entry.registrationNo}',
          pollAgency: entry.agency,
          surveyDate: detail.surveyDate ?? entry.registeredDate,
          supportRate: supportRate,
          partyName: member.party,
          sampleSize: detail.sampleSize,
          marginOfError: detail.marginOfError,
          source: entry.sourceUrl,
          notes:
              '${entry.client} | ${entry.method} | 지지율: ${supportRate ?? '미공개'}',
        ));
      }

      updatedMembers.add(member.copyWith(
        polls: _staticMergePolls(member.polls, newPolls),
        lastAnalysisDate: now,
      ));
    }
    return updatedMembers;
  }

  static String _staticMapDistrictToRegion(String district) {
    return getParentRegion(district) == '' ? '전국' : getParentRegion(district);
  }

  static bool _staticMatchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) return false;
    if (pollRegion.contains('전국') || pollRegion.contains(targetRegion)) {
      return true;
    }
    if (targetRegion == '전북특별자치도' && pollRegion.contains('전라북도')) {
      return true;
    }
    return false;
  }

  static List<String> _staticCandidateNameVariants(Member member) {
    final name = member.name.trim();
    if (name.isEmpty) return [];
    final variants = {name, name.replaceAll(' ', '')};
    const suffixes = ['후보', '후보자', '의원', '시장', '지사', '군수', '구청장', '위원장'];
    for (final s in suffixes) {
      variants.add('$name $s');
    }
    return variants.toList();
  }

  static List<String> _staticPartyAliases(String party) {
    const aliasMap = {
      '더불어민주당': ['더불어민주당', '민주당', '더불어 민주당', '민주'],
      '국민의힘': ['국민의힘', '국힘'],
    };
    return aliasMap[party] ?? [party];
  }

  static List<Poll> _staticMergePolls(
      List<Poll> existing, List<Poll> incoming) {
    final byId = {for (var p in existing) p.id: p};
    for (final p in incoming) {
      byId[p.id] = p;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return merged;
  }

  @override
  Future<void> apply2018RegionalPartyRates() async {
    final historicalRepo = sl<HistoricalElectionRepository>();
    final updatedMembers = <Member>[];
    for (final member in _dummyMembers) {
      final rates =
          await historicalRepo.get2018RegionalPartyRates(member.district);
      if (rates.isNotEmpty) {
        updatedMembers.add(member.copyWith(historical2018PartyRates: rates));
      }
    }
    if (updatedMembers.isNotEmpty) {
      await updateMembers(updatedMembers);
    }
  }

  @override
  Future<void> updateMember2018Rates(String memberId) async {
    final member = await getMemberById(memberId);
    final historicalRepo = sl<HistoricalElectionRepository>();
    final rates =
        await historicalRepo.get2018RegionalPartyRates(member.district);
    if (rates.isNotEmpty) {
      await updateMember(member.copyWith(historical2018PartyRates: rates));
    }
  }

  Future<void> _updateMemberImage(String memberName, String imageUrl) async {
    final index = _dummyMembers.indexWhere((m) => m.name == memberName);
    if (index != -1) {
      _dummyMembers[index] = _dummyMembers[index].copyWith(imageUrl: imageUrl);
      _notifyListeners();
    }
  }

  @override
  Future<void> updateParkSugiImage() async {
    await _updateMemberImage('박수기',
        'https://i.namu.wiki/i/s-gAQT2j5n9f8c1bB-A6w-p_i_u_e_q_z_w_y_x_v_C_D_E_F_G_H_I_J_K_L_M_N_O_P_Q_R_S_T_U_V_W_X_Y_Z.webp');
  }

  @override
  Future<void> updateSeoJaeyeolImage() async {
    await _updateMemberImage('서재열',
        'https://i.namu.wiki/i/R-1aB2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z.webp');
  }

  @override
  Future<void> updateYoonDaegiImage() async {
    await _updateMemberImage('윤대기',
        'https://i.namu.wiki/i/m-1p_3G9aX9bB3M_u_uC2j5pUPe9b29nNu2adYJ3Iq9223f2i1_fsK2j2-g_1gOqf_u2-3UfOa-z-g.webp');
  }

  @override
  Stream<List<Member>> watchMembers() {
    return _membersController.stream;
  }

  @override
  Stream<User?> watchCurrentUser() {
    return Stream.value(null);
  }

  @override
  Future<void> logout() async {
    // No-op in this implementation
  }
}
