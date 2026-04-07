import 'dart:async';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// 웹 안정화를 위한 로컬 메모리 기반 인증 리포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  static final Map<String, String> _accounts = <String, String>{};
  static User? _currentUser;

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  AuthRepositoryImpl();

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return AuthResult.failure('이메일과 비밀번호를 입력해주세요.');
    }

    final savedPassword = _accounts[normalizedEmail];
    if (savedPassword == null) {
      return AuthResult.failure('등록되지 않은 이메일입니다.');
    }

    if (savedPassword != password) {
      return AuthResult.failure('잘못된 비밀번호입니다.');
    }

    final now = DateTime.now();
    final user = User(
      id: normalizedEmail,
      email: normalizedEmail,
      displayName: normalizedEmail.split('@').first,
      provider: AuthProvider.email,
      createdAt: now,
      lastLoginAt: now,
    );
    _currentUser = user;
    _authStateController.add(user);
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return AuthResult.failure('이메일과 비밀번호를 입력해주세요.');
    }
    if (password.length < 6) {
      return AuthResult.failure('비밀번호는 6자 이상이어야 합니다.');
    }

    if (_accounts.containsKey(normalizedEmail)) {
      return AuthResult.failure('이미 사용 중인 이메일입니다.');
    }

    _accounts[normalizedEmail] = password;
    final now = DateTime.now();
    final user = User(
      id: normalizedEmail,
      email: normalizedEmail,
      displayName: normalizedEmail.split('@').first,
      provider: AuthProvider.email,
      createdAt: now,
      lastLoginAt: now,
    );
    _currentUser = user;
    _authStateController.add(user);
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return AuthResult.failure('웹 안정화 중이라 현재는 이메일 로그인만 지원합니다.');
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return AuthResult.failure('웹 안정화 중이라 현재는 이메일 로그인만 지원합니다.');
  }

  @override
  Future<AuthResult> signInWithFacebook() async {
    return AuthResult.failure('웹 안정화 중이라 현재는 이메일 로그인만 지원합니다.');
  }

  @override
  Future<AuthResult> signInWithKakao() async {
    return AuthResult.failure('웹 안정화 중이라 현재는 이메일 로그인만 지원합니다.');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final email = _currentUser?.email;
    if (email != null) {
      _accounts.remove(email);
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<User?> get authStateChanges {
    return _authStateController.stream;
  }
}
