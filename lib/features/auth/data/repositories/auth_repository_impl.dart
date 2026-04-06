import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth를 사용한 인증 리포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return _firebaseUserToUser(firebaseUser);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _firebaseUserToUser(result.user!);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('로그인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _firebaseUserToUser(result.user!);
      return AuthResult.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
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
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? _firebaseUserToUser(firebaseUser) : null;
    });
  }

  /// Firebase User를 도메인 User로 변환
  User _firebaseUserToUser(firebase.User firebaseUser) {
    AuthProvider provider = AuthProvider.anonymous;

    // 제공자 확인
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

  /// Firebase 에러 메시지 변환
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
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 있었습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }
}
