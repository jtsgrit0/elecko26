import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Firestore를 사용한 프로필 리포지토리 구현
class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _profilesCollection;

  ProfileRepositoryImpl({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _profilesCollection = (firestore ?? FirebaseFirestore.instance)
            .collection('user_profiles');

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _profilesCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()! as Map<String, dynamic>, userId);
      }
      return null;
    } catch (e) {
      throw Exception('프로필을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<ProfileUpdateResult> updateUserProfile(String userId, UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      await _profilesCollection.doc(userId).set(
        updatedProfile.toJson(),
        SetOptions(merge: true),
      );

      return ProfileUpdateResult.success(updatedProfile);
    } catch (e) {
      return ProfileUpdateResult.failure('프로필 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<bool> deleteUserProfile(String userId) async {
    try {
      await _profilesCollection.doc(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _profilesCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()! as Map<String, dynamic>, userId);
      }
      return null;
    });
  }
}