import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase를 사용한 인증 리포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthRepositoryImpl();

  User? _mapFirebaseUser(firebase_auth.User? user) {
    if (user == null) return null;
    
    // AuthProvider 매핑
    AuthProvider provider = AuthProvider.email;
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId == 'google.com') provider = AuthProvider.google;
      if (providerId == 'apple.com') provider = AuthProvider.apple;
    }

    return User(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      provider: provider,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime ?? DateTime.now(),
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    return _mapFirebaseUser(_firebaseAuth.currentUser);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) return AuthResult.failure('로그인에 실패했습니다.');
      return AuthResult.success(_mapFirebaseUser(credential.user)!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) return AuthResult.failure('회원가입에 실패했습니다.');
      return AuthResult.success(_mapFirebaseUser(credential.user)!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_handleAuthException(e));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.failure('구글 로그인이 취소되었습니다.');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) return AuthResult.failure('구글 로그인 연동에 실패했습니다.');

      return AuthResult.success(_mapFirebaseUser(userCredential.user)!);
    } catch (e) {
      return AuthResult.failure('구글 로그인 중 오류 발생: $e');
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScope.email,
          AppleIDAuthorizationScope.fullName,
        ],
      );

      final firebase_auth.OAuthProvider oAuthProvider = firebase_auth.OAuthProvider('apple.com');
      final firebase_auth.AuthCredential authCredential = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(authCredential);
      if (userCredential.user == null) return AuthResult.failure('애플 로그인 연동에 실패했습니다.');

      return AuthResult.success(_mapFirebaseUser(userCredential.user)!);
    } catch (e) {
      return AuthResult.failure('애플 로그인 중 오류 발생: $e');
    }
  }

  @override
  Future<AuthResult> signInWithFacebook() async {
    return AuthResult.failure('현재 Facebook 로그인은 지원하지 않습니다.');
  }

  @override
  Future<AuthResult> signInWithKakao() async {
    return AuthResult.failure('현재 Kakao 로그인은 지원하지 않습니다.');
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return '등록되지 않은 이메일입니다.';
      case 'wrong-password': return '비밀번호가 틀렸습니다.';
      case 'email-already-in-use': return '이미 사용 중인 이메일입니다.';
      case 'invalid-email': return '유효하지 않은 이메일 형식입니다.';
      case 'weak-password': return '비밀번호가 너무 취약합니다.';
      case 'operation-not-allowed': return '해당 인증 방식이 비활성화되어 있습니다.';
      default: return e.message ?? '인증 오류가 발생했습니다.';
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _authStateController.stream;
  }
}
