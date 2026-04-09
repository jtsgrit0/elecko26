import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:elecko26/data/models/member_model.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';

final sl = GetIt.instance;

class FirestoreMemberRepositoryImpl implements MemberRepository {
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
    
    // 1. 먼저 Firestore(Cloud)에서 시도
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
          debugPrint('[FirestoreMemberRepository] Successfully parsed ${loadedMembers.length} members from Cloud');
        }
      }
    } catch (e) {
      debugPrint('[FirestoreMemberRepository] Cloud Fetch Error: $e');
    }

    // 2. 만약 Cloud 데이터가 없다면 로컬 JSON 파일(Fallback)에서 로드
    if (loadedMembers.isEmpty) {
      try {
        debugPrint('[FirestoreMemberRepository] No cloud data or fetch failed. Falling back to local JSON...');
        String? jsonString;
        
        // GitHub Raw 시도
        try {
          final rawUrl = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
          final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            jsonString = utf8.decode(response.bodyBytes);
          }
        } catch (_) {}

        // 로컬 Asset 시도
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
          debugPrint('[FirestoreMemberRepository] Successfully parsed ${loadedMembers.length} members from Local Fallback');
        }
      } catch (e) {
        debugPrint('[FirestoreMemberRepository] Local Fallback Error: $e');
      }
    }

    // 3. 즐겨찾기 상태 반영 및 통지
    if (loadedMembers.isNotEmpty) {
      final localService = sl<LocalStorageService>();
      final favorites = await localService.getFavorites();
      final mappedMembers = loadedMembers.map((m) {
        return m.copyWith(isFavorite: favorites.contains(m.id));
      }).toList();
      _notifyListeners(mappedMembers);
    } else {
      debugPrint('[FirestoreMemberRepository] CRITICAL: No members loaded from any source.');
    }
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
