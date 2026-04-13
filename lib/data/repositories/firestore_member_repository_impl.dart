import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:elecko26/data/datasources/nesdc_poll_data_source.dart';
import 'package:elecko26/data/datasources/news_crawler.dart';
import 'package:elecko26/data/datasources/profile_image_resolver.dart';
import 'package:elecko26/data/models/member_model.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/entities/poll.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';

final sl = GetIt.instance;

class FirestoreMemberRepositoryImpl implements MemberRepository {
  // NESDC 여론조사 데이터 소스 엔진
  final NesdcPollDataSource _nesdcPollDataSource = NesdcPollDataSource(
    localStorageService: sl<LocalStorageService>(),
  );

  late final ProfileImageResolver _profileImageResolver = ProfileImageResolver(
    localStorageService: sl<LocalStorageService>(),
  );

  // Firebase 초기화 상태를 안전하게 확인하는 Getter
  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Firebase가 활성화되지 않았습니다. AppConfig를 확인해주세요.',
      );
    }
    return FirebaseFirestore.instance;
  }

  static final BehaviorSubject<List<Member>> _membersController =
      BehaviorSubject<List<Member>>.seeded([]);

  static final BehaviorSubject<String> _regionController =
      BehaviorSubject<String>();

  // Firestore 실시간 즐겨찾기 리스너
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _favoritesStreamSubscription;

  bool _isInitialized = false;

  void _notifyListeners(List<Member> members) {
    _membersController.add(List.from(members));
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        await _syncUserSettingsWithCloud();
      }
    } catch (_) {}
    // refreshMembers는 내부에서 비동기로 돌거나 즉시 첫 결과를 줄 수 있음
    await refreshMembers();
    _isInitialized = true;
  }

  auth.User? _getCurrentUserSafe() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return auth.FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}
    return null;
  }

  /// Firestore 즐겨찾기 실시간 리스너 시작
  void _startFavoritesStreamListener(String userId) {
    _stopFavoritesStreamListener();
    debugPrint('[FirestoreMemberRepository] Starting favorites stream listener for user: $userId');
    _favoritesStreamSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final cloudFavorites = List<String>.from(snapshot.data()!['favorites'] ?? []);
        debugPrint('[FirestoreMemberRepository] Firestore favorites changed: $cloudFavorites');
        // LocalStorage 업데이트
        _updateLocalStorageFromCloudFavorites(cloudFavorites);
        // UI 업데이트
        _updateMembersFavoriteStatus();
      }
    });
  }

  /// Firestore 즐겨찾기 실시간 리스너 중지
  void _stopFavoritesStreamListener() {
    _favoritesStreamSubscription?.cancel();
    _favoritesStreamSubscription = null;
    debugPrint('[FirestoreMemberRepository] Favorites stream listener cancelled');
  }

  /// Cloud Firestore 즐겨찾기로 LocalStorage 업데이트 (합집합)
  Future<void> _updateLocalStorageFromCloudFavorites(List<String> cloudFavorites) async {
    final localService = sl<LocalStorageService>();
    final localFavorites = await localService.getFavorites();
    // 합집합으로 병합 (Cloud 기준)
    for (final id in cloudFavorites) {
      if (!localFavorites.contains(id)) {
        await localService.addFavorite(id);
      }
    }
    // 로컬에는 있지만 Cloud에 없는 것은 제거 (Cloud가 권한)
    for (final id in List.from(localFavorites)) {
      if (!cloudFavorites.contains(id)) {
        await localService.removeFavorite(id);
      }
    }
  }

  Future<void> _syncUserSettingsWithCloud() async {
    final user = _getCurrentUserSafe();
    if (user == null) return;

    final localService = sl<LocalStorageService>();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      // 로컬 즐겨찾기 항상 로드
      final localFavorites = await localService.getFavorites();

      if (doc.exists) {
        final data = doc.data() ?? {};

        // 지역 동기화
        final cloudRegion = data['selectedRegion'] as String?;
        if (cloudRegion != null && cloudRegion.isNotEmpty) {
          await localService.saveSelectedRegion(cloudRegion);
        }

        // 즐겨찾기 양방향 동기화 (합집합 병합)
        final cloudFavorites = List<String>.from(data['favorites'] ?? []);
        final mergedSet = {...cloudFavorites, ...localFavorites};
        final mergedList = mergedSet.toList();

        // 로컬에 없는 Cloud 즐겨찾기를 로컬에 추가
        for (final id in cloudFavorites) {
          if (!localFavorites.contains(id)) {
            await localService.addFavorite(id);
          }
        }

        // 병합된 결과를 Cloud에 저장
        await _firestore.collection('users').doc(user.uid).set({
          'favorites': mergedList,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Cloud에 user document가 없으면 (신규 계정) 로컬 -> Cloud 업로드
        if (localFavorites.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).set({
            'favorites': localFavorites,
            'selectedRegion': await localService.getSelectedRegion(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // 멤버 리스트의 즐겨찾기 상태 갱신
      await _updateMembersFavoriteStatus();
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Sync error: $e');
    }
  }

  /// 현재 멤버 리스트의 즐겨찾기 상태를 로컬 저장소와 동기화
  Future<void> _updateMembersFavoriteStatus() async {
    final localService = sl<LocalStorageService>();
    final favorites = await localService.getFavorites();
    debugPrint('[FirestoreMemberRepository] _updateMembersFavoriteStatus: ${favorites.length} favorites found');
    final currentMembers = List<Member>.from(_membersController.value);
    debugPrint('[FirestoreMemberRepository] _updateMembersFavoriteStatus: ${currentMembers.length} members in controller');

    final updatedMembers = currentMembers.map((m) {
      final newFavStatus = favorites.contains(m.id);
      if (m.isFavorite != newFavStatus) {
        return m.copyWith(isFavorite: newFavStatus);
      }
      return m;
    }).toList();

    _membersController.add(updatedMembers);
    debugPrint('[FirestoreMemberRepository] _updateMembersFavoriteStatus: ${updatedMembers.where((m) => m.isFavorite).length} members marked as favorite');
  }

  @override
  Future<void> refreshMembers() async {
    List<Member> loadedMembers = [];
    final now = DateTime.now();

    // --- [1단계: 즉시 로딩] 의원 기본 정보 로드 ---

    // 1-1. Firestore(Cloud) 확인
    try {
      if (Firebase.apps.isNotEmpty) {
        final snapshot = await _firestore
            .collection('members')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 3));

        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              _normalizeFirestoreTimestamps(data);
              data['id'] = doc.id;
              loadedMembers.add(MemberModel.fromJson(data));
            } catch (e) {
              debugPrint('[FirestoreMemberRepository] Parse error: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Cloud Fetch Error: $e');
    }

    // 1-2. 로컬 JSON 후보군을 항상 로드하여 Cloud 일부 누락 케이스를 보강
    final fallbackMembers = await _loadFallbackMembers();
    if (loadedMembers.isEmpty) {
      loadedMembers = fallbackMembers;
    } else if (fallbackMembers.isNotEmpty) {
      loadedMembers =
          _mergeMembersByIdPreferCloud(loadedMembers, fallbackMembers);
    }

    // 1-3. 즉시 첫 번째 결과 통지 (의원 리스트 노출)
    if (loadedMembers.isNotEmpty) {
      final localService = sl<LocalStorageService>();
      final favorites = await localService.getFavorites();
      final preliminaryMembers = loadedMembers.map((m) {
        return m.copyWith(isFavorite: favorites.contains(m.id));
      }).toList();
      _notifyListeners(preliminaryMembers);
      debugPrint(
          '[FirestoreMemberRepository] Phase 1 complete: ${loadedMembers.length} members shown.');

      // --- [1.5단계: 백그라운드] 프로필 이미지 보강 ---
      _resolveMissingProfileImagesInBackground(preliminaryMembers);
    }

    // --- [2단계: 백그라운드 로딩] 여론조사 데이터 매칭 ---

    // 이 단계는 await 하지 않고 비동기로 처리하여 refreshMembers가 즉시 반환되게 할 수도 있지만,
    // _ensureInitialized에서 대기하므로 여기서는 별도 Isolate/Future로 넘깁니다.
    _performPollMatchingInBackground(loadedMembers, now);
  }

  Future<List<Member>> _loadFallbackMembers() async {
    final fallbackMembers = <Member>[];
    try {
      String? jsonString;
      try {
        final rawUrl =
            'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
        final response = await http
            .get(Uri.parse(rawUrl))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          jsonString = utf8.decode(response.bodyBytes);
        }
      } catch (_) {}

      jsonString ??=
          await rootBundle.loadString('data/election_candidates.json');

      final List<dynamic> jsonList = json.decode(jsonString);
      for (final item in jsonList) {
        try {
          fallbackMembers
              .add(MemberModel.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Local Fallback Error: $e');
    }
    return fallbackMembers;
  }

  List<Member> _mergeMembersByIdPreferCloud(
    List<Member> cloudMembers,
    List<Member> fallbackMembers,
  ) {
    final byId = <String, Member>{};

    for (final member in fallbackMembers) {
      final id = member.id.trim();
      if (id.isNotEmpty) byId[id] = member;
    }
    for (final member in cloudMembers) {
      final id = member.id.trim();
      if (id.isNotEmpty) byId[id] = member;
    }

    if (byId.isNotEmpty) {
      return byId.values.toList();
    }

    // 비정상 ID 데이터가 섞여 있을 때를 위한 이름 기반 보조 병합
    final byName = <String, Member>{};
    for (final member in fallbackMembers) {
      final key = member.name.trim();
      if (key.isNotEmpty) byName[key] = member;
    }
    for (final member in cloudMembers) {
      final key = member.name.trim();
      if (key.isNotEmpty) byName[key] = member;
    }
    return byName.values.toList();
  }

  Future<void> _performPollMatchingInBackground(
      List<Member> initialMembers, DateTime now) async {
    if (initialMembers.isEmpty) return;

    try {
      debugPrint(
          '[FirestoreMemberRepository] Phase 2 start: Matching polls in background...');
      final entries = await _nesdcPollDataSource.fetchLatest();

      // 최신 항목들 상세 정보 로드 (성능을 위해 제한)
      final List<Future<void>> detailTasks = [];
      for (var entry in entries.take(20)) {
        detailTasks.add(_nesdcPollDataSource.fetchDetail(entry.sourceUrl));
      }
      await Future.wait(detailTasks);

      final List<NesdcPollDetail> collectedDetails = entries
          .map((e) => _nesdcPollDataSource.getCachedDetail(e.sourceUrl))
          .whereType<NesdcPollDetail>()
          .toList();

      final updatedMembers = kIsWeb
          ? _matchPollsInBackground(
              List.from(initialMembers), entries, collectedDetails, now)
          : await Isolate.run(() => _matchPollsInBackground(
                List.from(initialMembers),
                entries,
                collectedDetails,
                now,
              ));

      // 2-2. 즐겨찾기 재적용 및 최종 통지
      final localService = sl<LocalStorageService>();
      final favorites = await localService.getFavorites();
      final finalMembers = updatedMembers.map((m) {
        return m.copyWith(isFavorite: favorites.contains(m.id));
      }).toList();

      _notifyListeners(finalMembers);
      debugPrint(
          '[FirestoreMemberRepository] Phase 2 complete: Polls matched and UI updated.');
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Phase 2 Match Failed: $e');
    }
  }

  Future<void> _resolveMissingProfileImagesInBackground(
      List<Member> initialMembers) async {
    // UX를 방해하지 않도록, 결과가 생길 때만 스트림을 한 번 더 갱신합니다.
    final candidates = initialMembers
        .where((m) =>
            m.imageUrl.trim().isEmpty &&
            _profileImageResolver.shouldAttempt(m.id))
        .take(15)
        .toList();
    if (candidates.isEmpty) return;

    try {
      bool changed = false;
      final updated = List<Member>.from(_membersController.value);

      for (final member in candidates) {
        final cached = _profileImageResolver.getCachedUrl(member.id);
        if (cached != null && cached.isNotEmpty) {
          final idx = updated.indexWhere((m) => m.id == member.id);
          if (idx != -1 && updated[idx].imageUrl.trim().isEmpty) {
            updated[idx] = updated[idx].copyWith(imageUrl: cached);
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
        final idx = updated.indexWhere((m) => m.id == member.id);
        if (idx != -1 && updated[idx].imageUrl.trim().isEmpty) {
          updated[idx] = updated[idx].copyWith(imageUrl: resolved);
          changed = true;
        }
      }

      if (changed) {
        _notifyListeners(updated);
        debugPrint(
            '[FirestoreMemberRepository] Profile images updated in background.');
      }
    } catch (e) {
      debugPrint(
          '[FirestoreMemberRepository] Profile image resolve failed: $e');
    }
  }

  // --- 여론조사 매칭 헬퍼 메서드들 ---

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
    final normalized = district.replaceAll(' ', '');
    const regionMap = {
      '서울': '서울특별시',
      '부산': '부산광역시',
      '대구': '대구광역시',
      '인천': '인천광역시',
      '광주': '광주광역시',
      '대전': '대전광역시',
      '울산': '울산광역시',
      '세종': '세종특별자치시',
      '경기': '경기도',
      '강원': '강원도',
      '충북': '충청북도',
      '충남': '충청남도',
      '전북': '전북특별자치도',
      '전남': '전라남도',
      '경북': '경상북도',
      '경남': '경상남도',
      '제주': '제주특별자치도',
    };
    for (final entry in regionMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return '전국';
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
    for (final p in incoming) byId[p.id] = p;
    final merged = byId.values.toList();
    merged.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return merged;
  }

  void _normalizeFirestoreTimestamps(Map<String, dynamic> data) {
    final dateFields = ['electionDate', 'lastAnalysisDate'];
    for (var field in dateFields) {
      if (data[field] is Timestamp) {
        data[field] = (data[field] as Timestamp).toDate().toIso8601String();
      }
    }

    final nestedFields = {
      'polls': 'surveyDate',
      'pressReports': 'publishDate',
      'socialContributions': 'date'
    };

    nestedFields.forEach((listField, dateField) {
      if (data[listField] != null) {
        for (var item in data[listField]) {
          if (item[dateField] is Timestamp) {
            item[dateField] =
                (item[dateField] as Timestamp).toDate().toIso8601String();
          }
        }
      }
    });
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await _ensureInitialized();
    return _membersController.value;
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    await _ensureInitialized();
    return _membersController.value;
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await _ensureInitialized();
    final members = _membersController.value;
    return members.firstWhere((m) => m.id == memberId,
        orElse: () => throw Exception('Not found'));
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    return _membersController.value
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.party.toLowerCase().contains(lowerQuery) ||
            m.district.toLowerCase().contains(lowerQuery) ||
            m.bio.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) {
    _ensureInitialized();
    return _membersController.stream;
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) {
    _ensureInitialized();
    return _membersController.stream.map((members) {
      try {
        return members.firstWhere((m) => m.id == memberId);
      } catch (e) {
        throw Exception('Not found');
      }
    });
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    final sanitizedId = memberId.trim();
    final localService = sl<LocalStorageService>();
    final isFav = await localService.isFavorite(sanitizedId);
    debugPrint('[FirestoreMemberRepository] toggleFavorite: $sanitizedId, wasFavorite: $isFav');

    // 1. LocalStorage 먼저 업데이트
    if (isFav) {
      await localService.removeFavorite(sanitizedId);
    } else {
      await localService.addFavorite(sanitizedId);
    }

    // 2. 즉시 UI 업데이트 (MemberRepositoryImpl과 동일한 방식)
    final currentMembers = List<Member>.from(_membersController.value);
    final idx = currentMembers.indexWhere((m) => m.id == sanitizedId);
    if (idx != -1) {
      // 대상 멤버만 토글 → 즉시 스트림 통지
      currentMembers[idx] = currentMembers[idx].copyWith(isFavorite: !isFav);
      _notifyListeners(currentMembers);
      debugPrint('[FirestoreMemberRepository] toggleFavorite: UI updated immediately for member');
    } else {
      // 대상 멤버가 현재 리스트에 없으면 전체 상태 재적용
      await _updateMembersFavoriteStatus();
    }

    // 3. Cloud 동기화는 백그라운드로 (UI 블로킹 방지)
    final user = _getCurrentUserSafe();
    if (user != null) {
      unawaited(_syncFavoriteToCloud(user.uid, localService));
    }
  }

  /// Cloud Firestore에 즐겨찾기 동기화 (백그라운드용)
  Future<void> _syncFavoriteToCloud(String userId, LocalStorageService localService) async {
    try {
      final favorites = await localService.getFavorites();
      await _firestore.collection('users').doc(userId).set({
        'favorites': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Failed to sync favorite to cloud: $e');
    }
  }

  @override
  Future<String> getSelectedRegion() async {
    if (_regionController.hasValue) {
      return _regionController.value;
    }
    final localService = sl<LocalStorageService>();
    final region = await localService.getSelectedRegion();
    _regionController.add(region);
    return region;
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    final localService = sl<LocalStorageService>();
    await localService.saveSelectedRegion(region);

    _regionController.add(region);

    final user = _getCurrentUserSafe();
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'selectedRegion': region,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint(
            '[FirestoreMemberRepository] Failed to sync region to cloud: $e');
      }
    }
  }

  @override
  Stream<String> watchSelectedRegion() {
    getSelectedRegion();
    return _regionController.stream;
  }

  @override
  Future<void> resetSettings() async {
    final localService = sl<LocalStorageService>();

    // 로그아웃 시 실시간 리스너 중지
    _stopFavoritesStreamListener();

    // 즐겨찾기는 Cloud에 동기화된 상태로 유지 (삭제하지 않음)
    // 투표 기록, 지역 설정만 초기화
    await localService.clearVotes();
    await localService.saveSelectedRegion('전국');
    _regionController.add('전국');

    // 멤버 리스트의 즐겨찾기 상태 갱신
    await _updateMembersFavoriteStatus();
  }

  @override
  Future<void> syncUserSettings() async {
    debugPrint('[FirestoreMemberRepository] syncUserSettings() called');
    final user = _getCurrentUserSafe();
    debugPrint('[FirestoreMemberRepository] Current user: ${user?.uid ?? 'null'}');
    if (user != null) {
      // 로그인 시 실시간 리스너 시작
      _startFavoritesStreamListener(user.uid);
      await _syncUserSettingsWithCloud();
    } else {
      // 로그아웃 시 리스너 중지
      _stopFavoritesStreamListener();
    }
    debugPrint('[FirestoreMemberRepository] syncUserSettings() updating favorite status');
    await _updateMembersFavoriteStatus();

    // 즐겨찾기된 후보들의 뉴스를 백그라운드로 수집
    unawaited(_crawlNewsForFavorites());

    debugPrint('[FirestoreMemberRepository] syncUserSettings() completed');
  }

  /// 즐겨찾기된 후보들의 뉴스를 백그라운드로 수집 (Naver 뉴스 검색)
  Future<void> _crawlNewsForFavorites() async {
    try {
      final localService = sl<LocalStorageService>();
      final favorites = await localService.getFavorites();
      if (favorites.isEmpty) return;

      final currentMembers = List<Member>.from(_membersController.value);
      final favoriteMembers =
          currentMembers.where((m) => favorites.contains(m.id)).toList();

      debugPrint(
          '[NewsCrawler] Crawling news for ${favoriteMembers.length} favorite members...');

      final crawler = NewsCrawler();
      bool hasUpdate = false;

      for (final member in favoriteMembers) {
        try {
          final newReports = await crawler.crawlNewsForCandidate(member.name);
          if (newReports.isEmpty) continue;

          final idx = currentMembers.indexWhere((m) => m.id == member.id);
          if (idx == -1) continue;

          // 기존 리포트와 병합 (URL 기준 중복 제거)
          final existingMember = currentMembers[idx] as MemberModel;
          final existingUrls =
              existingMember.pressReports.map((r) => r.url).toSet();
          final uniqueNewReports =
              newReports.where((r) => !existingUrls.contains(r.url)).toList();

          if (uniqueNewReports.isEmpty) continue;

          final mergedReports = [
            ...existingMember.pressReports,
            ...uniqueNewReports,
          ]..sort((a, b) => b.publishDate.compareTo(a.publishDate));

          // 최대 20개로 제한
          final limitedReports = mergedReports.take(20).toList();

          currentMembers[idx] = existingMember.copyWith(
            pressReports: limitedReports,
          );
          hasUpdate = true;

          debugPrint(
              '[NewsCrawler] Added ${uniqueNewReports.length} news for ${member.name}');
        } catch (e) {
          debugPrint('[NewsCrawler] Failed to crawl for ${member.name}: $e');
        }

        // 요청 간 지연 (rate limiting)
        await Future.delayed(const Duration(seconds: 1));
      }

      if (hasUpdate) {
        _notifyListeners(currentMembers);
        debugPrint('[NewsCrawler] UI updated with new news reports');
      }
    } catch (e) {
      debugPrint('[NewsCrawler] Error in crawlNewsForFavorites: $e');
    }
  }

  @override
  Future<void> addMember(Member member) async {
    if (member is MemberModel) {
      await _firestore
          .collection('members')
          .doc(member.id)
          .set(member.toJson());
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).delete();
  }

  @override
  Future<void> updateMember(Member member) async {
    if (member is MemberModel) {
      await _firestore
          .collection('members')
          .doc(member.id)
          .update(member.toJson());
    }
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    final batch = _firestore.batch();
    for (var member in members) {
      if (member is MemberModel) {
        final doc = _firestore.collection('members').doc(member.id);
        batch.set(doc, member.toJson(), SetOptions(merge: true));
      }
    }
    await batch.commit();
  }
}
