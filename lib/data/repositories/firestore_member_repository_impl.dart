import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:elecko26/data/models/member_model.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

final sl = GetIt.instance;

class FirestoreMemberRepositoryImpl implements MemberRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final BehaviorSubject<List<Member>> _membersController =
      BehaviorSubject<List<Member>>.seeded([]);

  bool _isInitialized = false;

  void _notifyListeners(List<Member> members) {
    _membersController.add(List.from(members));
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await refreshMembers();
    _isInitialized = true;
  }

  @override
  Future<void> refreshMembers() async {
    try {
      final snapshot = await _firestore.collection('members').get();
      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Firestore Timestamp to ISO string normalization
        if (data['electionDate'] is Timestamp) {
          data['electionDate'] = (data['electionDate'] as Timestamp).toDate().toIso8601String();
        }
        if (data['lastAnalysisDate'] is Timestamp) {
          data['lastAnalysisDate'] = (data['lastAnalysisDate'] as Timestamp).toDate().toIso8601String();
        }
        
        if (data['polls'] != null) {
          for (var p in data['polls']) {
            if (p['surveyDate'] is Timestamp) {
              p['surveyDate'] = (p['surveyDate'] as Timestamp).toDate().toIso8601String();
            }
          }
        }
        
        if (data['pressReports'] != null) {
          for (var p in data['pressReports']) {
            if (p['publishDate'] is Timestamp) {
              p['publishDate'] = (p['publishDate'] as Timestamp).toDate().toIso8601String();
            }
          }
        }

        if (data['socialContributions'] != null) {
          for (var s in data['socialContributions']) {
            if (s['date'] is Timestamp) {
              s['date'] = (s['date'] as Timestamp).toDate().toIso8601String();
            }
          }
        }
        
        // Override ID with document ID usually, or trust the doc data
        data['id'] = doc.id;
        
        return MemberModel.fromJson(data);
      }).toList();

      // Retrieve favorites from local storage
      final localService = sl<LocalStorageService>();
      final favorites = await localService.getFavorites();

      final mappedMembers = members.map((m) {
        return m.copyWith(isFavorite: favorites.contains(m.id));
      }).toList();

      _notifyListeners(mappedMembers);
    } catch (e) {
      print('Firebase Fetch Error: $e');
      // If collection doesn't exist or permissions fail, just notify empty or throw
    }
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
        // Return dummy/throw if not found.
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
  }

  @override
  Future<void> resetSettings() async {
    final localService = sl<LocalStorageService>();
    await localService.clearAll();
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
