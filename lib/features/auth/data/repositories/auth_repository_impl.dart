import 'dart:async';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// 플러그인 없이 동작하는 메모리 기반 이메일 인증 리포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  static final Map<String, Map<String, dynamic>> _accounts = {};
  static User? _currentUser;

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

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

    try {
      final account = _accounts[normalizedEmail];
      if (account == null) {
        return AuthResult.failure('등록되지 않은 이메일입니다.');
      }
      if ((account['password'] as String?) != password) {
        return AuthResult.failure('잘못된 비밀번호입니다.');
      }

      final now = DateTime.now();
      final user = User(
        id: account['id'] as String,
        email: normalizedEmail,
        displayName: account['displayName'] as String?,
        provider: AuthProvider.email,
        createdAt: DateTime.tryParse(account['createdAt'] as String? ?? '') ?? now,
        lastLoginAt: now,
      );

      account['lastLoginAt'] = now.toIso8601String();
      _accounts[normalizedEmail] = account;
      _currentUser = user;
      _authStateController.add(user);
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('로그인 중 오류가 발생했습니다: $e');
    }
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

    try {
      if (_accounts.containsKey(normalizedEmail)) {
        return AuthResult.failure('이미 사용 중인 이메일입니다.');
      }

      final now = DateTime.now();
      final user = User(
        id: 'local_${now.microsecondsSinceEpoch}',
        email: normalizedEmail,
        displayName: normalizedEmail.split('@').first,
        provider: AuthProvider.email,
        createdAt: now,
        lastLoginAt: now,
      );

      _accounts[normalizedEmail] = {
        'id': user.id,
        'email': normalizedEmail,
        'password': password,
        'displayName': user.displayName,
        'createdAt': now.toIso8601String(),
        'lastLoginAt': now.toIso8601String(),
      };

      _currentUser = user;
      _authStateController.add(user);
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return AuthResult.failure('구글 로그인은 현재 비활성화되어 있습니다.');
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return AuthResult.failure('Apple 로그인은 현재 비활성화되어 있습니다.');
  }

  @override
  Future<AuthResult> signInWithFacebook() async {
    return AuthResult.failure('페이스북 로그인은 현재 비활성화되어 있습니다.');
  }

  @override
  Future<AuthResult> signInWithKakao() async {
    return AuthResult.failure('카카오 로그인은 현재 비활성화되어 있습니다.');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || currentUser.email == null) {
      return;
    }

    _accounts.remove(currentUser.email!.toLowerCase());
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<User?> get authStateChanges {
    return Stream<User?>.multi((controller) async {
      controller.add(await getCurrentUser());
      final sub = _authStateController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }
}
