import 'dart:convert';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:elecko26/data/datasources/nesdc_poll_data_source.dart';
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
    await refreshMembers();
    _isInitialized = true;
  }

  Future<void> _syncUserSettingsWithCloud() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final localService = sl<LocalStorageService>();
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        
        final cloudRegion = data['selectedRegion'] as String?;
        if (cloudRegion != null && cloudRegion.isNotEmpty) {
          await localService.saveSelectedRegion(cloudRegion);
        }

        final cloudFavorites = List<String>.from(data['favorites'] ?? []);
        if (cloudFavorites.isNotEmpty) {
          final localFavorites = await localService.getFavorites();
          final mergedSet = {...cloudFavorites, ...localFavorites};
          final mergedList = mergedSet.toList();
          
          for (final id in mergedList) {
            if (!localFavorites.contains(id)) {
              await localService.addFavorite(id);
            }
          }
          
          await _firestore.collection('users').doc(user.uid).set({
            'favorites': mergedList,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Sync error: $e');
    }
  }

  @override
  Future<void> refreshMembers() async {
    List<Member> loadedMembers = [];
    final now = DateTime.now();
    
    // 1. 먼저 Firestore(Cloud)에서 의원 기본 정보 시도
    try {
      if (Firebase.apps.isNotEmpty) {
        final snapshot = await _firestore.collection('members').get();
        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              _normalizeFirestoreTimestamps(data);
              data['id'] = doc.id;
              loadedMembers.add(MemberModel.fromJson(data));
            } catch (e) {
              debugPrint('[FirestoreMemberRepository] Skipping member ${doc.id} due to parse error: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Cloud Fetch Error: $e');
    }

    // 2. 만약 Cloud 데이터가 없다면 로컬 JSON 파일(Fallback)에서 로드
    if (loadedMembers.isEmpty) {
      try {
        String? jsonString;
        try {
          final rawUrl = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
          final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            jsonString = utf8.decode(response.bodyBytes);
          }
        } catch (_) {}

        if (jsonString == null) {
          jsonString = await rootBundle.loadString('data/election_candidates.json');
        }

        if (jsonString != null) {
          final List<dynamic> jsonList = json.decode(jsonString);
          for (var item in jsonList) {
            try {
              loadedMembers.add(MemberModel.fromJson(item as Map<String, dynamic>));
            } catch (e) {
              final name = (item as Map)['name'] ?? 'Unknown';
              debugPrint('[FirestoreMemberRepository] Skipping local member $name due to parse error: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('[FirestoreMemberRepository] Local Fallback Error: $e');
      }
    }

    // 3. 실시간 여론조사(NESDC) 데이터 매칭 및 병합
    if (loadedMembers.isNotEmpty) {
      try {
        debugPrint('[FirestoreMemberRepository] Matching latest polls from NESDC...');
        final entries = await _nesdcPollDataSource.fetchLatest();
        
        // 상세 데이터 수집 (최근 5건 위주)
        final List<Future<void>> detailTasks = [];
        for (var entry in entries.take(30)) { // 성능을 위해 최근 30개 항목만 상세 확인
          detailTasks.add(_nesdcPollDataSource.fetchDetail(entry.sourceUrl));
        }
        await Future.wait(detailTasks);

        final List<NesdcPollDetail> collectedDetails = entries
            .map((e) => _nesdcPollDataSource.getCachedDetail(e.sourceUrl))
            .whereType<NesdcPollDetail>()
            .toList();

        // 매칭 로직 실행 (Web 환경 고려하여 Isolate/Direct 선택)
        final updatedMembers = kIsWeb
            ? _matchPollsInBackground(List.from(loadedMembers), entries, collectedDetails, now)
            : await Isolate.run(() => _matchPollsInBackground(
                List.from(loadedMembers),
                entries,
                collectedDetails,
                now,
              ));

        loadedMembers = updatedMembers;
        debugPrint('[FirestoreMemberRepository] Poll matching complete.');
      } catch (e, st) {
        debugPrint('[FirestoreMemberRepository] Poll Matching Failed: $e\n$st');
      }
    }

    // 4. 즐겨찾기 상태 반영 및 통지
    if (loadedMembers.isNotEmpty) {
      final localService = sl<LocalStorageService>();
      final favorites = await localService.getFavorites();
      final finalMembers = loadedMembers.map((m) {
        return m.copyWith(isFavorite: favorites.contains(m.id));
      }).toList();
      _notifyListeners(finalMembers);
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
        if (supportRate == null) {
          supportRate = detail.findSupportRate(partyAliases);
        }

        newPolls.add(Poll(
          id: 'nesdc_${entry.registrationNo}',
          pollAgency: entry.agency,
          surveyDate: detail.surveyDate ?? entry.registeredDate,
          supportRate: supportRate,
          partyName: member.party,
          sampleSize: detail.sampleSize,
          marginOfError: detail.marginOfError,
          source: entry.sourceUrl,
          notes: '${entry.client} | ${entry.method} | 지지율: ${supportRate ?? '미공개'}',
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
      '서울': '서울특별시', '부산': '부산광역시', '대구': '대구광역시', '인천': '인천광역시',
      '광주': '광주광역시', '대전': '대전광역시', '울산': '울산광역시', '세종': '세종특별자치시',
      '경기': '경기도', '강원': '강원도', '충북': '충청북도', '충남': '충청남도',
      '전북': '전북특별자치도', '전남': '전라남도', '경북': '경상북도', '경남': '경상남도', '제주': '제주특별자치도',
    };
    for (final entry in regionMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return '전국';
  }

  static bool _staticMatchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) return false;
    if (pollRegion.contains('전국') || pollRegion.contains(targetRegion)) return true;
    if (targetRegion == '전북특별자치도' && pollRegion.contains('전라북도')) return true;
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

  static List<Poll> _staticMergePolls(List<Poll> existing, List<Poll> incoming) {
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
            item[dateField] = (item[dateField] as Timestamp).toDate().toIso8601String();
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
    return members.firstWhere((m) => m.id == memberId, orElse: () => throw Exception('Not found'));
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
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)}) {
    _ensureInitialized();
    return _membersController.stream;
  }

  @override
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)}) {
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
    final localService = sl<LocalStorageService>();
    final isFav = await localService.isFavorite(memberId);
    
    if (isFav) {
      await localService.removeFavorite(memberId);
    } else {
      await localService.addFavorite(memberId);
    }
    
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final favorites = await localService.getFavorites();
        await _firestore.collection('users').doc(user.uid).set({
          'favorites': favorites,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[FirestoreMemberRepository] Failed to sync favorite to cloud: $e');
      }
    }
    
    final members = List<Member>.from(_membersController.value);
    final idx = members.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      members[idx] = members[idx].copyWith(isFavorite: !isFav);
      _notifyListeners(members);
    }
  }

  @override
  Future<String> getSelectedRegion() async {
    final localService = sl<LocalStorageService>();
    return await localService.getSelectedRegion();
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    final localService = sl<LocalStorageService>();
    await localService.saveSelectedRegion(region);

    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'selectedRegion': region,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[FirestoreMemberRepository] Failed to sync region to cloud: $e');
      }
    }
  }

  @override
  Future<void> resetSettings() async {
    final localService = sl<LocalStorageService>();
    await localService.clearAll();
  }
  
  @override
  Future<void> syncUserSettings() async {
    await _syncUserSettingsWithCloud();
    await refreshMembers();
  }
  
  @override
  Future<void> addMember(Member member) async {
    if (member is MemberModel) {
       await _firestore.collection('members').doc(member.id).set(member.toJson());
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).delete();
  }

  @override
  Future<void> updateMember(Member member) async {
    if (member is MemberModel) {
      await _firestore.collection('members').doc(member.id).update(member.toJson());
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
