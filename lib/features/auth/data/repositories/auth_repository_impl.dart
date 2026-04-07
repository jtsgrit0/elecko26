import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth 기반 인증 리포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  AuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return _firebaseUserToUser(firebaseUser);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return AuthResult.failure('이메일과 비밀번호를 입력해주세요.');
    }

    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = _firebaseUserToUser(result.user!);
      _authStateController.add(user);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
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
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = _firebaseUserToUser(result.user!);
      _authStateController.add(user);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final provider = firebase.GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final credential = await _signInWithProvider(provider);
      final user = _firebaseUserToUser(credential.user!);
      _authStateController.add(user);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('구글 로그인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final provider = firebase.OAuthProvider('apple.com');
      provider.addScope('email');
      provider.addScope('name');
      final credential = await _signInWithProvider(provider);
      final user = _firebaseUserToUser(credential.user!);
      _authStateController.add(user);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Apple 로그인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signInWithFacebook() async {
    try {
      final provider = firebase.FacebookAuthProvider();
      provider.addScope('email');
      final credential = await _signInWithProvider(provider);
      final user = _firebaseUserToUser(credential.user!);
      _authStateController.add(user);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('페이스북 로그인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signInWithKakao() async {
    try {
      final provider = firebase.OAuthProvider('oidc.kakao');
      provider.addScope('profile_nickname');
      provider.addScope('account_email');
      final credential = await _signInWithProvider(provider);
      final user = _firebaseUserToUser(credential.user!);
      _authStateController.add(user);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('카카오 로그인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _authStateController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
    _authStateController.add(null);
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? _firebaseUserToUser(firebaseUser) : null;
    });
  }

  Future<firebase.UserCredential> _signInWithProvider(
    firebase.AuthProvider provider,
  ) async {
    if (kIsWeb && provider is firebase.OAuthProvider) {
      return _firebaseAuth.signInWithPopup(provider);
    }
    if (kIsWeb && provider is firebase.FacebookAuthProvider) {
      return _firebaseAuth.signInWithPopup(provider);
    }
    if (kIsWeb && provider is firebase.GoogleAuthProvider) {
      return _firebaseAuth.signInWithPopup(provider);
    }
    throw UnsupportedError('이 플랫폼에서는 현재 소셜 로그인이 지원되지 않습니다.');
  }

  User _firebaseUserToUser(firebase.User firebaseUser) {
    AuthProvider provider = AuthProvider.anonymous;

    if (firebaseUser.providerData.isNotEmpty) {
      final providerId = firebaseUser.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          provider = AuthProvider.google;
          break;
        case 'apple.com':
          provider = AuthProvider.apple;
          break;
        case 'facebook.com':
          provider = AuthProvider.facebook;
          break;
        case 'oidc.kakao':
          provider = AuthProvider.kakao;
          break;
        case 'password':
          provider = AuthProvider.email;
          break;
      }
    }

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      provider: provider,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  String _getFirebaseErrorMessage(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'popup-blocked':
        return '브라우저가 로그인 팝업을 차단했습니다.';
      case 'account-exists-with-different-credential':
        return '다른 로그인 방식으로 이미 가입된 계정입니다.';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }
}
