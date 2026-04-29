import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:elecko26_new/data/datasources/local_storage_service.dart';
import 'package:elecko26_new/data/datasources/nesdc_poll_data_source.dart';
import 'package:elecko26_new/data/datasources/news_crawler.dart';
import 'package:elecko26_new/data/datasources/profile_image_resolver.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart'
    as domain_user;
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/usecases/possibility_calculator.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/domain/repositories/historical_election_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

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

  // ID 기반 고속 검색을 위한 Map 캐시
  static final Map<String, Member> _memberMap = {};

  // Firestore 실시간 즐겨찾기 리스너
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _favoritesStreamSubscription;

  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  // 캐시 키
  static const String _cacheKey = 'member_cache_v2';
  static const String _cacheTimestampKey = 'member_cache_timestamp_v2';
  // 캐시 유효 시간: 1시간
  static const Duration _cacheTtl = Duration(hours: 1);

  void _notifyListeners(List<Member> members) {
    // 고속 검색용 Map 업데이트
    _memberMap.clear();
    for (var m in members) {
      _memberMap[m.id] = m;
    }
    _membersController.add(List.from(members));
  }

  /// 브라우저 캐시에서 즉시 멤버 로드 (초고속)
  Future<List<Member>> _loadFromCache() async {
    try {
      final localService = sl<LocalStorageService>();
      final timestampStr = localService.getString(_cacheTimestampKey);
      if (timestampStr == null) return [];

      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
      if (DateTime.now().difference(timestamp) > _cacheTtl) {
        debugPrint('[Cache] 캐시 만료됨, 새로 로드 필요');
        return [];
      }

      final cachedJson = localService.getString(_cacheKey);
      if (cachedJson == null || cachedJson.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(cachedJson);
      final members = <Member>[];
      int count = 0;
      for (final item in jsonList) {
        try {
          members.add(MemberModel.fromJson(item as Map<String, dynamic>));
          count++;
          if (count % 500 == 0) await Future.delayed(Duration.zero);
        } catch (_) {}
      }
      debugPrint('[Cache] 캐시에서 ${members.length}명 즉시 로드 완료');
      return members;
    } catch (e) {
      debugPrint('[Cache] 캐시 로드 실패: $e');
      return [];
    }
  }

  /// 번들로 포함된 초경량 데이터 로드 (앱 최초 실행 시 즉시 화면 표시용)
  Future<List<Member>> _loadLightweightMembers() async {
    try {
      debugPrint('[Cache] Loading lightweight data from rootBundle...');
      final jsonString =
          await rootBundle.loadString('data/candidates_lightweight.json');
      final jsonList = json.decode(jsonString) as List<dynamic>;
      final members = <Member>[];

      int count = 0;
      for (final item in jsonList) {
        try {
          members.add(MemberModel.fromJson(item as Map<String, dynamic>));
          count++;
          // 웹에서 메인 스레드 점유 방지 (1000명마다 한번씩 양보)
          if (count % 1000 == 0) await Future.delayed(Duration.zero);
        } catch (_) {}
      }
      debugPrint('[Cache] 초경량 데이터 ${members.length}명 로드 완료');
      return members;
    } catch (e) {
      debugPrint('[Cache] 초경량 데이터 로드 실패: $e');
      return [];
    }
  }

  /// 전체 로드 완료 후 캐시 저장 (경량 필드만)
  Future<void> _saveToCache(List<Member> members) async {
    try {
      final localService = sl<LocalStorageService>();
      // 핵심 필드만 저장하여 용량 최소화 (이름, 정당, 지역, 당선가능성, 이미지)
      final lightweight = members
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'party': m.party,
                'district': m.district,
                'electionPossibility': m.electionPossibility,
                'imageUrl': m.imageUrl,
                'lastAnalysisDate': m.lastAnalysisDate?.toIso8601String() ?? '',
              })
          .toList();

      final jsonStr = json.encode(lightweight);
      // SharedPreferences는 약 10MB 제한이 있어 분할 저장
      if (jsonStr.length < 8 * 1024 * 1024) {
        await localService.setString(_cacheKey, jsonStr);
        await localService.setString(
          _cacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        debugPrint(
            '[Cache] ${members.length}명 캐시 저장 완료 (${(jsonStr.length / 1024).toStringAsFixed(1)}KB)');
      }
    } catch (e) {
      debugPrint('[Cache] 캐시 저장 실패: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_initializationFuture != null) {
      await _initializationFuture!.timeout(const Duration(seconds: 5),
          onTimeout: () {
        debugPrint('[FirestoreRepo] Initialization wait timeout');
      });
      return;
    }
    _initializationFuture = _performInitialization();
    await _initializationFuture!.timeout(const Duration(seconds: 5),
        onTimeout: () {
      debugPrint('[FirestoreRepo] Initialization perform timeout');
    });
  }

  Future<void> _performInitialization() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await _syncUserSettingsWithCloud();
      }
    } catch (_) {}
    try {
      // 1) 캐시에서 즉시 표시 (초고속) - 3초 내에 강제 완료
      var cachedMembers = await _loadFromCache()
          .timeout(const Duration(seconds: 3), onTimeout: () => []);

      // 캐시가 없으면 경량 번들 JSON에서 즉시 8000명 로드 (웹 환경 고려 8초 타임아웃)
      if (cachedMembers.isEmpty) {
        cachedMembers = await _loadLightweightMembers()
            .timeout(const Duration(seconds: 8), onTimeout: () => []);
      }

      if (cachedMembers.isNotEmpty) {
        final localService = sl<LocalStorageService>();
        final favoriteIds = await localService.getFavorites();
        final withFavorites = cachedMembers
            .map((m) => m.copyWith(isFavorite: favoriteIds.contains(m.id)))
            .toList();
        _notifyListeners(withFavorites);
        _isInitialized = true;
        debugPrint('[Cache] 즉시 표시 완료, 백그라운드 업데이트 시작...');
        // 2) 백그라운드에서 최신 데이터(상세)로 업데이트
        unawaited(refreshMembers());
      } else {
        // 둘 다 실패 시 풀 로드 시도 (10초 제한)
        await refreshMembers()
            .timeout(const Duration(seconds: 10), onTimeout: () {});
        _isInitialized = true;
      }
    } finally {
      _initializationFuture = null;
    }
  }

  void _ensureInitializedInBackground() {
    if (_isInitialized) return;
    unawaited(_ensureInitialized());
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
    debugPrint(
        '[FirestoreMemberRepository] Starting favorites stream listener for user: $userId');
    _favoritesStreamSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final cloudFavorites =
            List<String>.from(snapshot.data()!['favorites'] ?? []);
        debugPrint(
            '[FirestoreMemberRepository] Firestore favorites changed: $cloudFavorites');
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
    debugPrint(
        '[FirestoreMemberRepository] Favorites stream listener cancelled');
  }

  /// Cloud Firestore 즐겨찾기로 LocalStorage 업데이트 (합집합)
  Future<void> _updateLocalStorageFromCloudFavorites(
      List<String> cloudFavorites) async {
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

        await _mergeSupportVotes(localService, data['supportVotes']);

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
        final supportVotes = await _buildSupportVotesPayload(localService);
        await _firestore.collection('users').doc(user.uid).set({
          'favorites': mergedList,
          'supportVotes': supportVotes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Cloud에 user document가 없으면 (신규 계정) 로컬 -> Cloud 업로드
        final supportVotes = await _buildSupportVotesPayload(localService);
        if (localFavorites.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).set({
            'favorites': localFavorites,
            'selectedRegion': await localService.getSelectedRegion(),
            'supportVotes': supportVotes,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else if (supportVotes.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).set({
            'selectedRegion': await localService.getSelectedRegion(),
            'supportVotes': supportVotes,
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

  Future<void> _mergeSupportVotes(
    LocalStorageService localService,
    dynamic cloudVotesRaw,
  ) async {
    final localVotes = await localService.getAllVotes();
    final localTimestamps = await localService.getAllVoteTimestamps();
    final cloudVotes = _parseSupportVotes(cloudVotesRaw);

    final merged = <String, Map<String, dynamic>>{};

    for (final entry in localVotes.entries) {
      merged[entry.key] = {
        'memberId': entry.value,
        'timestamp': localTimestamps[entry.key],
      };
    }

    for (final entry in cloudVotes.entries) {
      final current = merged[entry.key];
      final currentTimestamp = (current?['timestamp'] as int?) ?? 0;
      final incomingTimestamp = (entry.value['timestamp'] as int?) ?? 0;
      if (current == null || incomingTimestamp >= currentTimestamp) {
        merged[entry.key] = entry.value;
      }
    }

    await localService.clearVotes();
    for (final entry in merged.entries) {
      final memberId = entry.value['memberId'] as String?;
      if (memberId == null || memberId.isEmpty) continue;
      await localService.saveVote(
        entry.key,
        memberId,
        timestamp: entry.value['timestamp'] as int?,
      );
    }
  }

  Map<String, Map<String, dynamic>> _parseSupportVotes(dynamic raw) {
    if (raw is! Map) return const {};

    final parsed = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      final district = entry.key.toString();
      final value = entry.value;
      if (value is Map) {
        final memberId = value['memberId']?.toString();
        if (memberId == null || memberId.isEmpty) continue;
        final timestampValue = value['timestamp'];
        parsed[district] = {
          'memberId': memberId,
          'timestamp': timestampValue is num ? timestampValue.toInt() : null,
        };
      }
    }
    return parsed;
  }

  Future<Map<String, Map<String, dynamic>>> _buildSupportVotesPayload(
    LocalStorageService localService,
  ) async {
    final votes = await localService.getAllVotes();
    final timestamps = await localService.getAllVoteTimestamps();

    final payload = <String, Map<String, dynamic>>{};
    for (final entry in votes.entries) {
      payload[entry.key] = {
        'memberId': entry.value,
        'timestamp': timestamps[entry.key],
      };
    }
    return payload;
  }

  Future<void> _syncSupportVotesToCloud(String userId) async {
    try {
      final localService = sl<LocalStorageService>();
      final supportVotes = await _buildSupportVotesPayload(localService);
      await _firestore.collection('users').doc(userId).set({
        'supportVotes': supportVotes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint(
          '[FirestoreMemberRepository] Failed to sync support votes: $e');
    }
  }

  /// 현재 멤버 리스트의 즐겨찾기 상태를 로컬 저장소와 동기화
  Future<void> _updateMembersFavoriteStatus() async {
    final localService = sl<LocalStorageService>();
    final favorites = await localService.getFavorites();
    debugPrint(
        '[FirestoreMemberRepository] _updateMembersFavoriteStatus: ${favorites.length} favorites found');
    final currentMembers = List<Member>.from(_membersController.value);
    debugPrint(
        '[FirestoreMemberRepository] _updateMembersFavoriteStatus: ${currentMembers.length} members in controller');

    final updatedMembers = currentMembers.map((m) {
      final newFavStatus = favorites.contains(m.id);
      if (m.isFavorite != newFavStatus) {
        return m.copyWith(isFavorite: newFavStatus);
      }
      return m;
    }).toList();

    _membersController.add(updatedMembers);
    debugPrint(
        '[FirestoreMemberRepository] _updateMembersFavoriteStatus: ${updatedMembers.where((m) => m.isFavorite).length} members marked as favorite');
  }

  // 김재식 님의 프로필 이미지 URL을 업데이트
  Future<void> updateKimJaesikImage() async {
    await _ensureInitialized();
    try {
      const String kimJaesikImageUrl =
          'https://img1.daumcdn.net/thumb/R658x0.q70/?fname=https://t1.daumcdn.net/news/202603/18/551730-ch1iKEu/20260318200506839ispp.jpg';

      // 이름이 '김재식'인 멤버 찾기
      final querySnapshot = await _firestore
          .collection('members')
          .where('name', isEqualTo: '김재식')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 첫 번째 김재식 문서 업데이트
        final doc = querySnapshot.docs.first;
        await doc.reference.update({'imageUrl': kimJaesikImageUrl});
        debugPrint('김재식 님의 프로필 이미지가 업데이트되었습니다.');

        // 로컬 캐시도 업데이트
        await refreshMembers();
      } else {
        debugPrint('김재식 님을 찾을 수 없습니다.');
      }
    } catch (e) {
      debugPrint('김재식 님 프로필 이미지 업데이트 중 오류: $e');
    }
  }

  @override
  Future<void> refreshMembers() async {
    final now = DateTime.now();
    final localService = sl<LocalStorageService>();
    final favoriteIds = await localService.getFavorites();

    // --- [0단계] 로컬 캐시/에셋에서 즉시 로드 (사용자 체감 속도 0ms) ---
    if (_membersController.value.isEmpty) {
      var cachedMembers = await _loadFromCache();
      if (cachedMembers.isEmpty) {
        cachedMembers = await _loadLightweightMembers();
      }

      if (cachedMembers.isNotEmpty) {
        final withFavorites = cachedMembers
            .map((m) => m.copyWith(isFavorite: favoriteIds.contains(m.id)))
            .toList();
        _notifyListeners(withFavorites);
        debugPrint(
            '[FirestoreMemberRepo] Phase 0 (Local Cache ${withFavorites.length}명) 즉시 표시 완료');
      }
    }

    // --- [1단계] Firestore 및 로컬 에셋 업데이트 (백그라운드 진행) ---
    // 아래 과정은 비동기로 진행하여 UI 스레드 점유를 최소화함
    _performFullRefreshInBackground(favoriteIds, now);
  }

  Future<void> _performFullRefreshInBackground(
      List<String> favoriteIds, DateTime now) async {
    debugPrint('[Refresh] === Background Full Refresh Started ===');
    List<Member> cloudMembers = [];
    try {
      debugPrint('[Refresh] Phase 1: Fetching cloud data...');
      if (Firebase.apps.isNotEmpty) {
        // 서버와 캐시를 동시에 보되, 2초 내에 응답 없으면 넘어가기
        final snapshot = await _firestore
            .collection('members')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 2));

        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            try {
              // 중요: Firestore 웹 등에서 반환된 Map이 수정 불가능(unmodifiable)일 수 있으므로 복사본 생성
              final data = Map<String, dynamic>.from(doc.data());
              _normalizeFirestoreTimestamps(data);
              data['id'] = doc.id;
              cloudMembers.add(MemberModel.fromJson(data));
            } catch (e) {
              debugPrint(
                  '[FirestoreMemberRepository] Error parsing doc ${doc.id}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Cloud Fetch Skip/Error: $e');
    }

    if (cloudMembers.isNotEmpty) {
      final preliminary = cloudMembers
          .map((m) => m.copyWith(isFavorite: favoriteIds.contains(m.id)))
          .toList();
      _notifyListeners(preliminary);
      debugPrint('[FirestoreMemberRepository] Phase 1 (Cloud Sync) 완료');
    }

    // --- [2단계] 로컬 에셋 파일을 백그라운드에서 순차 로드 ---
    await _loadAssetsAndMergeInBackground(cloudMembers, favoriteIds, now);
  }

  /// 로컬 split JSON 파일을 순차적으로 로드하며 점진적으로 UI 업데이트
  Future<void> _loadAssetsAndMergeInBackground(
    List<Member> cloudMembers,
    List<String> favoriteIds,
    DateTime now,
  ) async {
    final allLocalMembers = <Member>[];
    final selectedRegion = await getSelectedRegion();

    final regions = [
      '서울특별시',
      '부산광역시',
      '대구광역시',
      '인천광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '세종특별자치시',
      '경기도',
      '강원도',
      '충청북도',
      '충청남도',
      '전북특별자치도',
      '전라남도',
      '경상북도',
      '경상남도',
      '제주특별자치도',
      '기타'
    ];

    // 1) 우선순위: 사용자가 선택한 지역 먼저 로드
    if (selectedRegion != null && selectedRegion != '전국') {
      try {
        final content = await _loadAssetSplitChunk(selectedRegion);
        final chunk = await _parseMembersFromJsonChunk(content, favoriteIds);
        allLocalMembers.addAll(chunk);

        // 지역 데이터 로드 즉시 반영 (가장 빠른 피드백)
        final preliminary =
            _mergeMembersByIdPreferCloud(cloudMembers, allLocalMembers);
        _notifyListeners(preliminary);
        debugPrint(
            '[FirestoreMemberRepository] 우선순위 지역 ($selectedRegion) 로드 및 UI 반영 완료');
      } catch (e) {
        debugPrint('[FirestoreMemberRepository] 우선순위 지역 로드 실패: $e');
      }
    }

    // 2) 나머지 지역 백그라운드 순차 로드
    for (var region in regions) {
      if (region == selectedRegion) continue;

      try {
        final content = await _loadAssetSplitChunk(region);
        final chunk = await _parseMembersFromJsonChunk(content, favoriteIds);
        allLocalMembers.addAll(chunk);

        // 브라우저 프레임 확보
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        debugPrint('[FirestoreMemberRepository] 지역 ($region) 로드 실패: $e');
      }
    }

    // 최종 데이터 병합 및 반영
    final finalMembers =
        _mergeMembersByIdPreferCloud(cloudMembers, allLocalMembers);
    _notifyListeners(finalMembers);
    debugPrint(
        '[FirestoreMemberRepository] 전체 지역 (${finalMembers.length}명) 병합 완료');

    // 다음 방문 시 즉시 표시를 위해 캐시에 저장 (백그라운드)
    unawaited(_saveToCache(finalMembers));

    // 무거운 작업은 UI 스레드를 방해하지 않도록 아주 짧은 지연 후 비동기 실행
    await Future.delayed(const Duration(milliseconds: 100));
    _resolveMissingProfileImagesInBackground(finalMembers);
    _performPollMatchingInBackground(finalMembers, now);
  }

  Future<List<Member>> _loadSplitMembersFromRemote(
    List<String> favoriteIds,
    List<Member> cloudMembers,
  ) async {
    final members = <Member>[];
    final regions = [
      '서울특별시',
      '부산광역시',
      '대구광역시',
      '인천광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '세종특별자치시',
      '경기도',
      '강원도',
      '충청북도',
      '충청남도',
      '전북특별자치도',
      '전라남도',
      '경상북도',
      '경상남도',
      '제주특별자치도',
      '기타'
    ];

    try {
      for (var region in regions) {
        final content = await _loadRemoteSplitChunk(region);
        if (content == null) continue;

        final chunk = await _parseMembersFromJsonChunk(content, favoriteIds);
        members.addAll(chunk);

        if (members.isNotEmpty) {
          final merged = _mergeMembersByIdPreferCloud(cloudMembers, members);
          _notifyListeners(merged);
        }

        await Future.delayed(const Duration(milliseconds: 10));
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Split remote load failed: $e');
    }

    return members;
  }

  Future<List<Member>> _loadSplitMembersFromAssets(
    List<String> favoriteIds,
  ) async {
    final members = <Member>[];
    final regions = [
      '서울특별시',
      '부산광역시',
      '대구광역시',
      '인천광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '세종특별자치시',
      '경기도',
      '강원도',
      '충청북도',
      '충청남도',
      '전북특별자치도',
      '전라남도',
      '경상북도',
      '경상남도',
      '제주특별자치도',
      '기타'
    ];

    for (var region in regions) {
      try {
        final content = await _loadAssetSplitChunk(region);
        final chunk = await _parseMembersFromJsonChunk(content, favoriteIds);
        members.addAll(chunk);
      } catch (_) {}
    }
    return members;
  }

  Future<String?> _loadRemoteSplitChunk(String identifier) async {
    try {
      final rawUrl =
          'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/candidates_split/candidates_$identifier.json';
      final response = await http
          .get(Uri.parse(rawUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }
    } catch (_) {}

    return null;
  }

  Future<String> _loadAssetSplitChunk(String identifier) async {
    try {
      return await rootBundle.loadString(
        'data/candidates_split/candidates_$identifier.json',
      );
    } catch (_) {}

    throw FlutterError(
        'Split candidate asset not found: identifier=$identifier');
  }

  static Future<List<Member>> _parseMembersFromJsonChunk(
    String jsonString,
    List<String> favoriteIds,
  ) async {
    final favoriteSet = favoriteIds.toSet();
    final members = <Member>[];

    final jsonList = json.decode(jsonString) as List<dynamic>;
    int count = 0;
    for (final item in jsonList) {
      try {
        final member = MemberModel.fromJson(item as Map<String, dynamic>);
        members.add(
          member.copyWith(isFavorite: favoriteSet.contains(member.id)),
        );

        count++;
        if (count % 100 == 0) {
          await Future.delayed(Duration.zero);
        }
      } catch (_) {}
    }

    return members;
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

      final updatedMembers = await _matchPollsInBackground(
          List.from(initialMembers), entries, collectedDetails, now);

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

        final resolved = await _profileImageResolver.resolveImageUrlByName(
          member.name,
          party: member.party,
          district: member.district,
        );
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

  static Future<List<Member>> _matchPollsInBackground(
    List<Member> members,
    List<NesdcPollEntry> entries,
    List<NesdcPollDetail> details,
    DateTime now,
  ) async {
    final detailMap = {for (var d in details) d.detailUrl: d};
    final updatedMembers = <Member>[];

    // 성능 최적화 1: 지역별 그룹화 (O(E * R))
    final regions = [
      '서울특별시',
      '부산광역시',
      '대구광역시',
      '인천광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '세종특별자치시',
      '경기도',
      '강원도',
      '충청북도',
      '충청남도',
      '전북특별자치도',
      '전라남도',
      '경상북도',
      '경상남도',
      '제주특별자치도',
      '전국'
    ];

    final Map<String, List<NesdcPollEntry>> entriesByRegion = {};
    for (var region in regions) {
      entriesByRegion[region] = entries
          .where((e) => _staticMatchesRegion(e.region, region))
          .toList()
        ..sort((a, b) => b.registeredDate.compareTo(a.registeredDate));
    }

    // 성능 최적화 2: 각 멤버에 대해 사전 분류된 리스트에서 추출 및 변경된 멤버만 재계산
    int count = 0;
    for (var member in members) {
      count++;
      if (count % 100 == 0) {
        await Future.delayed(Duration.zero);
      }
      final regionKey = _staticMapDistrictToRegion(member.district);
      final matchedEntries = entriesByRegion[regionKey] ?? [];

      final limitedEntries = matchedEntries.take(5).toList();
      final newPolls = <Poll>[];

      final candidateNames = _staticCandidateNameVariants(member);
      final partyAliases = _staticPartyAliases(member.party);

      for (var entry in limitedEntries) {
        final detail = detailMap[entry.sourceUrl];
        if (detail == null) continue;

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

      final mergedPolls = _staticMergePolls(member.polls, newPolls);

      // 여론조사가 추가되었거나 변경된 경우에만 재계산 진행
      if (mergedPolls.length != member.polls.length) {
        final updatedMember = member.copyWith(
          polls: mergedPolls,
          lastAnalysisDate: now,
        );

        final scores = PossibilityCalculator.calculateMultiFactorScores(
          member: updatedMember,
          historicalBaseSupport: 0.5,
        );

        updatedMembers.add(updatedMember.copyWith(
          electionPossibility: scores['overall']!,
        ));
      } else {
        // 변경 사항이 없으면 그대로 유지 (성능 절약)
        updatedMembers.add(member);
      }
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
      if (normalized.contains(entry.key) || normalized.contains(entry.value)) {
        return entry.value;
      }
    }
    return '전국';
  }

  static bool _staticMatchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) return false;
    if (pollRegion.contains('전국')) return true;

    final p = pollRegion.replaceAll(' ', '');
    final t = targetRegion.replaceAll(' ', '');

    // Handle mutual containment (e.g., '부산' and '부산광역시')
    if (p.contains(t) || t.contains(p)) {
      return true;
    }

    // Special cases for provinces with common abbreviations
    if ((p.contains('경북') && t.contains('경상북도')) ||
        (p.contains('경남') && t.contains('경상남도')) ||
        (p.contains('전북') && (t.contains('전라북도') || t.contains('전북'))) ||
        (p.contains('전남') && t.contains('전라남도')) ||
        (p.contains('충북') && t.contains('충청북도')) ||
        (p.contains('충남') && t.contains('충청남도')) ||
        (p.contains('강원') && t.contains('강원'))) {
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
      if (data[listField] != null && data[listField] is List) {
        final List<dynamic> originalList = data[listField];
        final List<dynamic> mutableList = [];
        bool modified = false;

        for (var originalItem in originalList) {
          if (originalItem is Map) {
            final Map<String, dynamic> item =
                Map<String, dynamic>.from(originalItem);
            if (item[dateField] is Timestamp) {
              item[dateField] =
                  (item[dateField] as Timestamp).toDate().toIso8601String();
              modified = true;
            }
            mutableList.add(item);
          } else {
            mutableList.add(originalItem);
          }
        }

        if (modified) {
          data[listField] = mutableList;
        }
      }
    });
  }

  @override
  Future<List<Member>> getAllMembers() async {
    debugPrint(
        '[FirestoreMemberRepository] Getting all members from Firestore');
    await _ensureInitialized();

    try {
      final snapshot = await _firestore.collection('members').get();
      final localService = sl<LocalStorageService>();
      final favoriteIds = await localService.getFavorites();

      if (snapshot.docs.isEmpty) {
        debugPrint(
            '[FirestoreMemberRepository] No members found in Firestore, attempting to load from lightweight bundle.');
        return _loadLightweightMembers();
      }

      final members = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['isFavorite'] = favoriteIds.contains(doc.id);
        return MemberModel.fromJson(data);
      }).toList();

      debugPrint(
          '[FirestoreMemberRepository] Successfully loaded ${members.length} members from Firestore.');
      _notifyListeners(members);
      unawaited(_saveToCache(members));
      return members;
    } catch (e, stackTrace) {
      debugPrint('[FirestoreMemberRepository] Error getting all members: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint(
          '[FirestoreMemberRepository] Falling back to lightweight bundle.');
      return _loadLightweightMembers();
    }
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    _ensureInitializedInBackground();
    return _membersController.value;
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    // 1단계: 고속 Map 캐시 확인
    if (_memberMap.containsKey(memberId)) {
      _ensureInitializedInBackground();
      return _memberMap[memberId]!;
    }

    // 2단계: 리스트 검색 (폴백)
    final cachedMembers = _membersController.value;
    final cachedIndex = cachedMembers.indexWhere((m) => m.id == memberId);
    if (cachedIndex != -1) {
      _ensureInitializedInBackground();
      return cachedMembers[cachedIndex];
    }

    // 3단계: 초기화 후 재검색
    await _ensureInitialized();
    if (_memberMap.containsKey(memberId)) {
      return _memberMap[memberId]!;
    }

    final members = _membersController.value;
    return members.firstWhere((m) => m.id == memberId,
        orElse: () => throw Exception('Not found: $memberId'));
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    if (_membersController.value.isEmpty) {
      await _ensureInitialized();
    } else {
      _ensureInitializedInBackground();
    }
    final lowerQuery = query.toLowerCase();
    return _membersController.value
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.party.toLowerCase().contains(lowerQuery) ||
            m.district.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) {
    _ensureInitializedInBackground();
    return _membersController.stream;
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) {
    _ensureInitializedInBackground();

    final cachedMembers = _membersController.value;
    final cachedIndex = cachedMembers.indexWhere((m) => m.id == memberId);
    final Member? cachedMember =
        cachedIndex != -1 ? cachedMembers[cachedIndex] : null;

    final stream = _membersController.stream
        .where((members) => members.any((m) => m.id == memberId))
        .map((members) => members.firstWhere((m) => m.id == memberId));
    // .distinct() 제거: isFavorite 변경 시에도 스트림 전파되도록

    return cachedMember != null ? stream.startWith(cachedMember) : stream;
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    final sanitizedId = memberId.trim();
    final localService = sl<LocalStorageService>();
    final isFav = await localService.isFavorite(sanitizedId);
    debugPrint(
        '[FirestoreMemberRepository] toggleFavorite: $sanitizedId, wasFavorite: $isFav');

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
      debugPrint(
          '[FirestoreMemberRepository] toggleFavorite: UI updated immediately for member');
    } else {
      // 대상 멤버가 현재 리스트에 없으면 전체 상태 재적용
      await _updateMembersFavoriteStatus();
    }

    // 3. Cloud 동기화는 백그라운드로 (UI 블로킹 방지)
    final user = _getCurrentUserSafe();
    if (user != null) {
      unawaited(_syncFavoriteToCloud(user.uid, localService));
    }

    // 4. 즐겨찾기된 후보의 뉴스를 백그라운드로 수집
    unawaited(_crawlNewsForFavorites());
  }

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) async {
    final localService = sl<LocalStorageService>();
    await localService.saveVote(district, memberId, timestamp: timestamp);

    final user = _getCurrentUserSafe();
    if (user != null) {
      await _syncSupportVotesToCloud(user.uid);
    }
  }

  @override
  Future<void> removeSupportVote(String district) async {
    final localService = sl<LocalStorageService>();
    await localService.removeVote(district);

    final user = _getCurrentUserSafe();
    if (user != null) {
      await _syncSupportVotesToCloud(user.uid);
    }
  }

  /// Cloud Firestore에 즐겨찾기 동기화 (백그라운드용)
  Future<void> _syncFavoriteToCloud(
      String userId, LocalStorageService localService) async {
    try {
      final favorites = await localService.getFavorites();
      await _firestore.collection('users').doc(userId).set({
        'favorites': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint(
          '[FirestoreMemberRepository] Failed to sync favorite to cloud: $e');
    }
  }

  @override
  Future<String?> getSelectedRegion() async {
    if (_regionController.hasValue && _regionController.value.isNotEmpty) {
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
  Stream<Map<String, String>> watchAllVotes() {
    return sl<LocalStorageService>().watchAllVotes();
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
    debugPrint(
        '[FirestoreMemberRepository] Current user: ${user?.uid ?? 'null'}');
    if (user != null) {
      // 로그인 시 실시간 리스너 시작
      _startFavoritesStreamListener(user.uid);
      await _syncUserSettingsWithCloud();
    } else {
      // 로그아웃 시 리스너 중지
      _stopFavoritesStreamListener();
    }
    debugPrint(
        '[FirestoreMemberRepository] syncUserSettings() updating favorite status');
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
  Future<void> apply2018RegionalPartyRates() async {
    await _ensureInitialized();

    try {
      final historicalRepo = sl<HistoricalElectionRepository>();
      final members = await getAllMembers();
      final updatedMembers = <Member>[];

      for (final member in members) {
        // 의원의 지역구로 2018년 득표율 조회
        final regionalRates =
            await historicalRepo.get2018RegionalPartyRates(member.district);

        if (regionalRates.isNotEmpty) {
          // 2018년 득표율이 있는 경우 업데이트
          final updatedMember =
              member.copyWith(historical2018PartyRates: regionalRates);
          updatedMembers.add(updatedMember);

          debugPrint(
              '${member.name} (${member.district})의 2018년 득표율 업데이트: $regionalRates');
        }
      }

      // 업데이트된 회원들을 일괄 저장
      if (updatedMembers.isNotEmpty) {
        await updateMembers(updatedMembers);
        debugPrint('총 ${updatedMembers.length}명의 의원 2018년 득표율 업데이트 완료');
      }
    } catch (e) {
      debugPrint('2018년 지방선거 득표율 반영 중 오류: $e');
    }
  }

  @override
  Future<void> updateMember2018Rates(String memberId) async {
    await _ensureInitialized();

    try {
      final member = await getMemberById(memberId);
      final historicalRepo = sl<HistoricalElectionRepository>();

      // 해당 의원의 지역구로 2018년 득표율 조회
      final regionalRates =
          await historicalRepo.get2018RegionalPartyRates(member.district);

      if (regionalRates.isNotEmpty) {
        // 2018년 득표율이 있는 경우 업데이트
        final updatedMember =
            member.copyWith(historical2018PartyRates: regionalRates);
        await updateMember(updatedMember);

        debugPrint(
            '${member.name} (${member.district})의 2018년 득표율 업데이트: $regionalRates');
      }
    } catch (e) {
      debugPrint('${memberId} 의원의 2018년 득표율 업데이트 중 오류: $e');
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

  @override
  // 박수기 후보의 프로필 이미지 URL을 업데이트
  Future<void> updateParkSugiImage() async {
    await _ensureInitialized();
    try {
      const String parkSugiImageUrl =
          'https://cpmadang.org/sites/default/files/100142312.JPG';

      // member_sugi_gwangsan ID를 가진 박수기 후보 찾기
      final doc = await _firestore
          .collection('members')
          .doc('member_sugi_gwangsan')
          .get();

      if (doc.exists) {
        await doc.reference.update({'imageUrl': parkSugiImageUrl});
        debugPrint('박수기 후보(광산구청장)의 프로필 이미지가 업데이트되었습니다.');

        // 로컬 캐시도 업데이트
        await refreshMembers();
      } else {
        debugPrint('박수기 후보(member_sugi_gwangsan)를 찾을 수 없습니다.');
      }
    } catch (e) {
      debugPrint('박수기 후보 프로필 이미지 업데이트 중 오류: $e');
    }
  }

  @override
  // 윤대기 후보의 프로필 이미지 URL을 업데이트
  Future<void> updateYoonDaegiImage() async {
    await _ensureInitialized();
    try {
      const String yoonDaegiImageUrl =
          'https://wimg.kyeongin.com/news/cms/2026/02/03/news-p.v1.20260203.184429b9bc80491b96a8a5114aa2e092_P3.jpg';

      // member_daegi ID를 가진 윤대기 후보 찾기
      final doc =
          await _firestore.collection('members').doc('member_daegi').get();

      if (doc.exists) {
        await doc.reference.update({'imageUrl': yoonDaegiImageUrl});
        debugPrint('윤대기 후보(인천 계양을)의 프로필 이미지가 업데이트되었습니다.');

        // 로컬 캐시도 업데이트
        await refreshMembers();
      } else {
        debugPrint('윤대기 후보(member_daegi)를 찾을 수 없습니다.');
      }
    } catch (e) {
      debugPrint('윤대기 후보 프로필 이미지 업데이트 중 오류: $e');
    }
  }

  @override
  // 서재열 후보의 프로필 이미지 URL을 업데이트
  Future<void> updateSeoJaeyeolImage() async {
    await _ensureInitialized();
    try {
      const String seoJaeyeolImageUrl =
          'https://dimg.donga.com/wps/NEWS/IMAGE/2004/02/16/6913540.1.jpg';

      // member_jaeyeol ID를 가진 서재열 후보 찾기
      final doc =
          await _firestore.collection('members').doc('member_jaeyeol').get();

      if (doc.exists) {
        await doc.reference.update({'imageUrl': seoJaeyeolImageUrl});
        debugPrint('서재열 후보(경기 평택을)의 프로필 이미지가 업데이트되었습니다.');

        // 로컬 캐시도 업데이트
        await refreshMembers();
      } else {
        debugPrint('서재열 후보(member_jaeyeol)를 찾을 수 없습니다.');
      }
    } catch (e) {
      debugPrint('서재열 후보 프로필 이미지 업데이트 중 오류: $e');
    }
  }

  @override
  Stream<List<Member>> watchMembers() {
    _ensureInitializedInBackground();
    return _membersController.stream;
  }

  @override
  Stream<domain_user.User?> watchCurrentUser() {
    if (Firebase.apps.isEmpty) return Stream.value(null);
    return auth.FirebaseAuth.instance.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        _stopFavoritesStreamListener();
        return null;
      }
      _startFavoritesStreamListener(firebaseUser.uid);

      domain_user.AuthProvider provider;
      if (firebaseUser.providerData.isEmpty) {
        provider = domain_user.AuthProvider.anonymous;
      } else {
        final providerId = firebaseUser.providerData.first.providerId;
        if (providerId.contains('google')) {
          provider = domain_user.AuthProvider.google;
        } else if (providerId.contains('apple')) {
          provider = domain_user.AuthProvider.apple;
        } else {
          provider = domain_user.AuthProvider.anonymous;
        }
      }

      return domain_user.User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        provider: provider,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      );
    });
  }

  @override
  Future<void> crawlNewsForAllMembers() async {
    debugPrint('[NewsCrawler] 모든 후보자 뉴스 크롤링을 시작합니다...');
    try {
      // 1. 모든 후보자 정보 가져오기
      final membersSnapshot = await _firestore.collection('members').get();
      final allMembers = membersSnapshot.docs
          .map((doc) => MemberModel.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();

      if (allMembers.isEmpty) {
        debugPrint('[NewsCrawler] 업데이트할 후보자가 없습니다.');
        return;
      }

      debugPrint('[NewsCrawler] ${allMembers.length}명의 후보자를 대상으로 크롤링을 시작합니다.');

      final newsCrawler = NewsCrawler();
      final WriteBatch batch = _firestore.batch();
      int updatedCount = 0;

      // 2. 각 후보자에 대해 뉴스 크롤링 및 업데이트
      for (int i = 0; i < allMembers.length; i++) {
        final member = allMembers[i];
        debugPrint(
            '[NewsCrawler] (${i + 1}/${allMembers.length}) ${member.name} 후보의 뉴스를 크롤링합니다...');

        try {
          final newReports =
              await newsCrawler.crawlNewsForCandidate(member.name);

          if (newReports.isEmpty) {
            debugPrint('[NewsCrawler] ${member.name} 후보의 새 뉴스가 없습니다.');
            continue;
          }

          // 3. 기존 뉴스 리포트와 병합 (중복 제거 및 정렬)
          final existingReports = member.pressReports;
          final existingUrls = existingReports.map((r) => r.url).toSet();

          final uniqueNewReports =
              newReports.where((r) => !existingUrls.contains(r.url)).toList();

          if (uniqueNewReports.isEmpty) {
            debugPrint('[NewsCrawler] ${member.name} 후보의 중복되지 않은 새 뉴스가 없습니다.');
            continue;
          }

          final mergedReports = [...uniqueNewReports, ...existingReports]
            ..sort((a, b) => b.publishDate.compareTo(a.publishDate));

          // 4. 최대 20개로 제한
          final limitedReports = mergedReports.take(20).toList();

          final memberRef = _firestore.collection('members').doc(member.id);
          batch.update(memberRef, {
            'pressReports': limitedReports.map((r) => r.toJson()).toList(),
            'lastAnalysisDate': FieldValue.serverTimestamp(), // 뉴스 업데이트 시각 반영
          });

          updatedCount++;
          debugPrint(
              '[NewsCrawler] ${member.name} 후보의 뉴스 ${uniqueNewReports.length}건을 추가합니다.');
        } catch (e) {
          debugPrint('[NewsCrawler] ${member.name} 후보 뉴스 크롤링 중 오류: $e');
        }

        // 5. 요청 간 지연 (과도한 요청 방지)
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (updatedCount > 0) {
        // 6. 일괄 업데이트 실행
        await batch.commit();
        debugPrint('[NewsCrawler] 총 ${updatedCount}명의 후보자 뉴스를 성공적으로 업데이트했습니다.');
      } else {
        debugPrint('[NewsCrawler] 업데이트할 새로운 뉴스가 없습니다.');
      }
    } catch (e) {
      debugPrint('[NewsCrawler] 전체 뉴스 크롤링 프로세스 중 심각한 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    if (Firebase.apps.isEmpty) return;
    await auth.FirebaseAuth.instance.signOut();
    _stopFavoritesStreamListener();
  }
}
