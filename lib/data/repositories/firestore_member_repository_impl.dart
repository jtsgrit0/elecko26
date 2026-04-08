import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:elecko26/data/models/member_model.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/entities/poll.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

final sl = GetIt.instance;

/// Firestore를 이용해 의원 목록과 사용자 즐겨찾기/설정 데이터를 영구 저장합니다.
///
/// 저장 구조:
/// - `members` 컬렉션: 후보자/의원 데이터를 문서 단위로 저장
/// - `users/{uid}` 문서: 사용자별 즐겨찾기 목록과 지역 설정을 저장
///   - `favorite_member_ids`: List<String>
///   - `selected_region`: String
///   - `updated_at`: Timestamp
class FirestoreMemberRepositoryImpl implements MemberRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  bool _refreshInProgress = false;

  FirestoreMemberRepositoryImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _membersCollection =>
      _firestore.collection('members').withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data() ?? {},
        toFirestore: (value, _) => value,
      );

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  String? get _currentUid => _auth.currentUser?.uid;

  Future<void> _ensureUserDocumentExists() async {
    final uid = _currentUid;
    if (uid == null) {
      return;
    }

    final docRef = _userDocument(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'favorite_member_ids': <String>[],
        'selected_region': '전국',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>> _loadUserMetadata() async {
    final uid = _currentUid;
    if (uid == null) {
      return _loadLocalUserMetadata();
    }

    try {
      final docRef = _userDocument(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await _ensureUserDocumentExists();
        return {
          'favorite_member_ids': <String>[],
          'selected_region': '전국',
        };
      }

      return snapshot.data() ?? {
        'favorite_member_ids': <String>[],
        'selected_region': '전국',
      };
    } catch (e, st) {
      print('[FirestoreMemberRepo] _loadUserMetadata failed, using local fallback: $e');
      print(st);
      return _loadLocalUserMetadata();
    }
  }

  Map<String, dynamic> _loadLocalUserMetadata() {
    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      return {
        'favorite_member_ids': prefs.getStringList('favorite_member_ids') ?? <String>[],
        'selected_region': prefs.getString('user_selected_region') ?? '전국',
      };
    }
    return {
      'favorite_member_ids': <String>[],
      'selected_region': '전국',
    };
  }

  Future<Set<String>> _loadFavoriteIds() async {
    final metadata = await _loadUserMetadata();
    if (metadata['favorite_member_ids'] is List) {
      return Set<String>.from((metadata['favorite_member_ids'] as List).whereType<String>());
    }
    return {};
  }

  Future<String> _loadSelectedRegionValue() async {
    final metadata = await _loadUserMetadata();
    return metadata['selected_region'] as String? ?? '전국';
  }

  Member _memberFromFirestoreData(Map<String, dynamic> data, String id, Set<String> favoriteIds) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    List<T> parseStringList<T>(dynamic raw) {
      if (raw is List) {
        return raw.whereType<T>().toList();
      }
      return <T>[];
    }

    List<PressReport> parsePressReports(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map((item) {
          return PressReport(
            id: item['id'] as String? ?? '',
            title: item['title'] as String? ?? '',
            source: item['source'] as String? ?? '',
            url: item['url'] as String? ?? '',
            publishDate: parseDate(item['publishDate']),
            summary: item['summary'] as String? ?? '',
            sentiment: item['sentiment'] as String? ?? 'neutral',
          );
        }).toList();
      }
      return <PressReport>[];
    }

    List<Poll> parsePolls(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map((item) {
          final supportRate = item['supportRate'];
          final sampleSize = item['sampleSize'];
          final marginOfError = item['marginOfError'];
          return Poll(
            id: item['id'] as String? ?? '',
            pollAgency: item['pollAgency'] as String? ?? '',
            surveyDate: parseDate(item['surveyDate']),
            supportRate: supportRate == null ? null : (supportRate as num).toDouble(),
            partyName: item['partyName'] as String? ?? '',
            sampleSize: sampleSize == null ? null : (sampleSize as num).toInt(),
            marginOfError: marginOfError == null ? null : (marginOfError as num).toDouble(),
            source: item['source'] as String? ?? '',
            notes: item['notes'] as String?,
          );
        }).toList();
      }
      return <Poll>[];
    }

    List<SocialContribution> parseSocialContributions(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map((item) {
          return SocialContribution(
            title: item['title'] as String? ?? '',
            date: parseDate(item['date']),
            type: item['type'] as String? ?? '',
            amount: item['amount'] as String?,
            summary: item['summary'] as String? ?? '',
          );
        }).toList();
      }
      return <SocialContribution>[];
    }

    return Member(
      id: id,
      name: data['name'] as String? ?? '',
      party: data['party'] as String? ?? '',
      district: data['district'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      electionDate: parseDate(data['electionDate']),
      term: (data['term'] as num?)?.toInt() ?? 0,
      achievementsList: parseStringList<String>(data['achievementsList']),
      actions: parseStringList<String>(data['actions']),
      policies: parseStringList<String>(data['policies']),
      pressReports: parsePressReports(data['pressReports']),
      polls: parsePolls(data['polls']),
      electionPossibility: (data['electionPossibility'] as num?)?.toDouble() ?? 0.0,
      lastAnalysisDate: parseDate(data['lastAnalysisDate']),
      improvementPoints: parseStringList<String>(data['improvementPoints']),
      socialContributions: parseSocialContributions(data['socialContributions']),
      isFavorite: favoriteIds.contains(id),
    );
  }

  Map<String, dynamic> _memberToFirestore(Member member) {
    return MemberModel(
      id: member.id,
      name: member.name,
      party: member.party,
      district: member.district,
      imageUrl: member.imageUrl,
      bio: member.bio,
      electionDate: member.electionDate,
      term: member.term,
      achievementsList: member.achievementsList,
      actions: member.actions,
      policies: member.policies,
      pressReports: member.pressReports,
      polls: member.polls,
      electionPossibility: member.electionPossibility,
      lastAnalysisDate: member.lastAnalysisDate,
      improvementPoints: member.improvementPoints,
      socialContributions: member.socialContributions,
      isFavorite: member.isFavorite,
    ).toJson();
  }

  @override
  Future<void> addMember(Member member) async {
    await _membersCollection.doc(member.id).set(_memberToFirestore(member));
  }

  @override
  Future<void> updateMember(Member member) async {
    await _membersCollection.doc(member.id).set(_memberToFirestore(member), SetOptions(merge: true));
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    final batch = _firestore.batch();
    for (final member in members) {
      final docRef = _membersCollection.doc(member.id);
      batch.set(docRef, _memberToFirestore(member), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _membersCollection.doc(memberId).delete();
  }

  @override
  Future<List<Member>> getAllMembers() async {
    final favoriteIds = await _loadFavoriteIds();
    try {
      final querySnapshot = await _membersCollection.get();
      final members = querySnapshot.docs
          .map((doc) => _memberFromFirestoreData(doc.data(), doc.id, favoriteIds))
          .toList();

      if (members.isNotEmpty) {
        return members;
      }

      print('[FirestoreMemberRepo] Firestore members empty, using remote fallback');
      return await _fetchMembersFromRemote(favoriteIds);
    } catch (e, st) {
      print('[FirestoreMemberRepo] Firestore getAllMembers failed, using remote fallback: $e');
      print(st);
      return await _fetchMembersFromRemote(favoriteIds);
    }
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    return await getAllMembers();
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    final favoriteIds = await _loadFavoriteIds();
    try {
      final docSnapshot = await _membersCollection.doc(memberId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return _memberFromFirestoreData(docSnapshot.data()!, memberId, favoriteIds);
      }
    } catch (e, st) {
      print('[FirestoreMemberRepo] getMemberById firestore lookup failed: $e');
      print(st);
    }

    final members = await _fetchMembersWithFallback(favoriteIds);
    try {
      return members.firstWhere((member) => member.id == memberId);
    } catch (_) {
      throw Exception('Member not found');
    }
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    final allMembers = await getAllMembers();
    final lowerQuery = query.toLowerCase();
    return allMembers.where((m) {
      return m.name.toLowerCase().contains(lowerQuery) ||
          m.party.toLowerCase().contains(lowerQuery) ||
          m.district.toLowerCase().contains(lowerQuery) ||
          m.bio.toLowerCase().contains(lowerQuery) ||
          m.policies.any((p) => p.toLowerCase().contains(lowerQuery)) ||
          m.achievementsList.any((a) => a.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)}) async* {
    try {
      await refreshMembers();
    } catch (e, st) {
      print('[FirestoreMemberRepo] watchAllMembers initial refresh failed: $e');
      print(st);
    }

    yield await _safeGetAllMembers();

    yield* Stream.periodic(interval).asyncMap((_) async {
      try {
        await refreshMembers();
      } catch (e, st) {
        print('[FirestoreMemberRepo] watchAllMembers periodic refresh failed: $e');
        print(st);
      }
      return await _safeGetAllMembers();
    });
  }

  @override
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)}) async* {
    try {
      await refreshMembers();
    } catch (e, st) {
      print('[FirestoreMemberRepo] watchMemberById initial refresh failed: $e');
      print(st);
    }

    final firstMember = await _safeGetMemberById(memberId);
    if (firstMember != null) {
      yield firstMember;
    }

    while (true) {
      await Future.delayed(interval);
      try {
        await refreshMembers();
      } catch (e, st) {
        print('[FirestoreMemberRepo] watchMemberById periodic refresh failed: $e');
        print(st);
      }
      final member = await _safeGetMemberById(memberId);
      if (member != null) {
        yield member;
      }
    }
  }

  Future<List<Member>> _safeGetAllMembers() async {
    try {
      return await getAllMembers();
    } catch (e, st) {
      print('[FirestoreMemberRepo] getAllMembers failed: $e');
      print(st);
      return [];
    }
  }

  Future<Member?> _safeGetMemberById(String memberId) async {
    try {
      return await getMemberById(memberId);
    } catch (e, st) {
      print('[FirestoreMemberRepo] getMemberById failed: $e');
      print(st);
      return null;
    }
  }

  Future<void> _setUserMetadata(Map<String, dynamic> updates) async {
    final uid = _currentUid;
    if (uid != null) {
      await _userDocument(uid).set({
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> refreshMembers() async {
    if (_refreshInProgress) {
      return;
    }
    _refreshInProgress = true;

    try {
      final favoriteIds = await _loadFavoriteIds();
      final members = await _fetchMembersWithFallback(favoriteIds);

      for (final member in members) {
        try {
          await _membersCollection.doc(member.id).set(
            _memberToFirestore(member),
          );
        } catch (e) {
          print('[FirestoreMemberRepo] Member sync error for ${member.name}: $e');
        }
      }
    } catch (e) {
      print('[FirestoreMemberRepo] Refresh failed: $e');
    } finally {
      _refreshInProgress = false;
    }
  }

  List<Member> _parseMembersFromJson(String decodedBody, Set<String> favoriteIds) {
    final List<dynamic> jsonList = json.decode(decodedBody);
    return jsonList.map((item) {
      final newMember = MemberModel.fromJson(item as Map<String, dynamic>);
      return newMember.copyWith(
        isFavorite: favoriteIds.contains(newMember.id),
      );
    }).toList();
  }

  Future<List<Member>> _fetchMembersFromRemote(Set<String> favoriteIds) async {
    try {
      final rawUrl = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
      final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        print('[FirestoreMemberRepo] Remote fallback failed with status: ${response.statusCode}');
        return await _fetchMembersFromAsset(favoriteIds);
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      return _parseMembersFromJson(decodedBody, favoriteIds);
    } catch (e, st) {
      print('[FirestoreMemberRepo] Remote fallback fetch failed: $e');
      print(st);
      return await _fetchMembersFromAsset(favoriteIds);
    }
  }

  Future<List<Member>> _fetchMembersFromAsset(Set<String> favoriteIds) async {
    try {
      final decodedBody = await rootBundle.loadString('data/election_candidates.json');
      print('[FirestoreMemberRepo] Loaded local asset fallback for election_candidates.json');
      return _parseMembersFromJson(decodedBody, favoriteIds);
    } catch (e, st) {
      print('[FirestoreMemberRepo] Asset fallback failed: $e');
      print(st);
      return [];
    }
  }

  Future<List<Member>> _fetchMembersWithFallback(Set<String> favoriteIds) async {
    final remoteMembers = await _fetchMembersFromRemote(favoriteIds);
    if (remoteMembers.isNotEmpty) {
      return remoteMembers;
    }
    return await _fetchMembersFromAsset(favoriteIds);
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    final uid = _currentUid;
    if (uid != null) {
      final currentFavorites = await _loadFavoriteIds();
      final newFavorites = Set<String>.from(currentFavorites);
      if (newFavorites.contains(memberId)) {
        newFavorites.remove(memberId);
      } else {
        newFavorites.add(memberId);
      }
      await _setUserMetadata({'favorite_member_ids': newFavorites.toList()});
    }

    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      final favoriteIds = prefs.getStringList('favorite_member_ids') ?? [];
      if (favoriteIds.contains(memberId)) {
        favoriteIds.remove(memberId);
      } else {
        favoriteIds.add(memberId);
      }
      await prefs.setStringList('favorite_member_ids', favoriteIds);
    }
  }

  @override
  Future<void> resetSettings() async {
    final uid = _currentUid;
    if (uid != null) {
      await _userDocument(uid).set({
        'favorite_member_ids': [],
        'selected_region': '전국',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      await prefs.clear();
    }
  }

  @override
  Future<String> getSelectedRegion() async {
    final uid = _currentUid;
    if (uid != null) {
      return await _loadSelectedRegionValue();
    }

    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      return prefs.getString('user_selected_region') ?? '전국';
    }
    return '전국';
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    final uid = _currentUid;
    if (uid != null) {
      await _setUserMetadata({'selected_region': region});
    }

    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      await prefs.setString('user_selected_region', region);
    }
  }
}
