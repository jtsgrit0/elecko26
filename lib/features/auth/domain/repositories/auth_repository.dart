import '../entities/user.dart';

/// 인증 리포지토리 인터페이스
abstract class AuthRepository {
  /// 현재 사용자 가져오기
  Future<User?> getCurrentUser();

  /// 이메일/비밀번호 로그인
  Future<AuthResult> signInWithEmail(String email, String password);

  /// 이메일/비밀번호 회원가입
  Future<AuthResult> signUpWithEmail(String email, String password);

  /// 구글 로그인
  Future<AuthResult> signInWithGoogle();

  /// 로그아웃
  Future<void> signOut();

  /// 사용자 삭제
  Future<void> deleteAccount();

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges;
}
