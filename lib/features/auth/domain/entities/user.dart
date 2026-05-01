/// 인증 관련 엔티티들

/// 사용자 엔티티
class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// 인증 제공자 타입
enum AuthProvider {
  email,
  google,
  apple,
  facebook,
  kakao,
  anonymous,
}

/// 로그인 결과
class AuthResult {
  final User? user;
  final String? errorMessage;
  final bool isSuccess;

  AuthResult({
    this.user,
    this.errorMessage,
    required this.isSuccess,
  });

  factory AuthResult.success(User user) {
    return AuthResult(user: user, isSuccess: true);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(errorMessage: errorMessage, isSuccess: false);
  }
}
