import '../entities/profile.dart';

/// 프로필 리포지토리 인터페이스
abstract class ProfileRepository {
  /// 사용자 프로필 가져오기
  Future<UserProfile?> getUserProfile(String userId);

  /// 사용자 프로필 생성/업데이트
  Future<ProfileUpdateResult> updateUserProfile(String userId, UserProfile profile);

  /// 사용자 프로필 삭제
  Future<bool> deleteUserProfile(String userId);

  /// 프로필 변경사항 스트림
  Stream<UserProfile?> watchUserProfile(String userId);
}