/// 프로필 관련 엔티티들

/// 사용자 프로필 엔티티
class UserProfile {
  final String userId;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? location;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.location,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? birthDate,
    String? gender,
    String? location,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore에서 변환
  factory UserProfile.fromJson(Map<String, dynamic> json, String userId) {
    return UserProfile(
      userId: userId,
      displayName: json['displayName'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['birthDate'] as int)
          : null,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  /// Firestore로 변환
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'gender': gender,
      'location': location,
      'preferences': preferences,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

/// 프로필 업데이트 결과
class ProfileUpdateResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserProfile? updatedProfile;

  ProfileUpdateResult({
    required this.isSuccess,
    this.errorMessage,
    this.updatedProfile,
  });

  factory ProfileUpdateResult.success(UserProfile profile) {
    return ProfileUpdateResult(
      isSuccess: true,
      updatedProfile: profile,
    );
  }

  factory ProfileUpdateResult.failure(String errorMessage) {
    return ProfileUpdateResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}