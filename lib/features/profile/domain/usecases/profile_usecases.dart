import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// 프로필 유스케이스 베이스 클래스
abstract class ProfileUseCase {
  final ProfileRepository repository;

  ProfileUseCase(this.repository);
}

/// 사용자 프로필 가져오기 유스케이스
class GetUserProfileUseCase extends ProfileUseCase {
  GetUserProfileUseCase(super.repository);

  Future<UserProfile?> execute(String userId) async {
    return await repository.getUserProfile(userId);
  }
}

/// 사용자 프로필 업데이트 유스케이스
class UpdateUserProfileUseCase extends ProfileUseCase {
  UpdateUserProfileUseCase(super.repository);

  Future<ProfileUpdateResult> execute(String userId, UserProfile profile) async {
    return await repository.updateUserProfile(userId, profile);
  }
}

/// 사용자 프로필 삭제 유스케이스
class DeleteUserProfileUseCase extends ProfileUseCase {
  DeleteUserProfileUseCase(super.repository);

  Future<bool> execute(String userId) async {
    return await repository.deleteUserProfile(userId);
  }
}

/// 프로필 초기화 유스케이스 (새 사용자용)
class InitializeUserProfileUseCase extends ProfileUseCase {
  InitializeUserProfileUseCase(super.repository);

  Future<ProfileUpdateResult> execute(String userId, {
    String? displayName,
    String? email,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      userId: userId,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );

    return await repository.updateUserProfile(userId, profile);
  }
}