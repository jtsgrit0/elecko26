import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// 로컬 스토리지를 사용하는 이메일 인증 리포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  static const _accountsKey = 'auth_accounts_v1';
  static const _currentUserKey = 'auth_current_user_v1';

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_currentUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return _userFromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_currentUserKey);
      return null;
    }
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return AuthResult.failure('이메일과 비밀번호를 입력해주세요.');
    }

    try {
      final prefs = await _prefs;
      final accounts = await _loadAccounts();
      final account = accounts[normalizedEmail];
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
      accounts[normalizedEmail] = account;
      await prefs.setString(_accountsKey, json.encode(accounts));
      await prefs.setString(_currentUserKey, json.encode(_userToJson(user)));
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
      final prefs = await _prefs;
      final accounts = await _loadAccounts();
      if (accounts.containsKey(normalizedEmail)) {
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

      accounts[normalizedEmail] = {
        'id': user.id,
        'email': normalizedEmail,
        'password': password,
        'displayName': user.displayName,
        'createdAt': now.toIso8601String(),
        'lastLoginAt': now.toIso8601String(),
      };

      await prefs.setString(_accountsKey, json.encode(accounts));
      await prefs.setString(_currentUserKey, json.encode(_userToJson(user)));
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
    final prefs = await _prefs;
    await prefs.remove(_currentUserKey);
    _authStateController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null || currentUser.email == null) {
      return;
    }

    final prefs = await _prefs;
    final accounts = await _loadAccounts();
    accounts.remove(currentUser.email!.toLowerCase());
    await prefs.setString(_accountsKey, json.encode(accounts));
    await prefs.remove(_currentUserKey);
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

  Future<Map<String, Map<String, dynamic>>> _loadAccounts() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        Map<String, dynamic>.from(value as Map),
      ),
    );
  }

  Map<String, dynamic> _userToJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'provider': user.provider.name,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLoginAt': user.lastLoginAt.toIso8601String(),
    };
  }

  User _userFromJson(Map<String, dynamic> jsonMap) {
    return User(
      id: jsonMap['id'] as String,
      email: jsonMap['email'] as String?,
      displayName: jsonMap['displayName'] as String?,
      photoUrl: jsonMap['photoUrl'] as String?,
      provider: AuthProvider.values.firstWhere(
        (provider) => provider.name == jsonMap['provider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt: DateTime.tryParse(jsonMap['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastLoginAt: DateTime.tryParse(jsonMap['lastLoginAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
