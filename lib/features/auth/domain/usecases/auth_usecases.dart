import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// 인증 유스케이스 베이스 클래스
abstract class AuthUseCase {
  final AuthRepository repository;

  AuthUseCase(this.repository);
}

/// 현재 사용자 가져오기 유스케이스
class GetCurrentUserUseCase extends AuthUseCase {
  GetCurrentUserUseCase(super.repository);

  Future<User?> execute() async {
    return await repository.getCurrentUser();
  }
}

/// 이메일 로그인 유스케이스
class SignInWithEmailUseCase extends AuthUseCase {
  SignInWithEmailUseCase(super.repository);

  Future<AuthResult> execute(String email, String password) async {
    return await repository.signInWithEmail(email, password);
  }
}

/// 이메일 회원가입 유스케이스
class SignUpWithEmailUseCase extends AuthUseCase {
  SignUpWithEmailUseCase(super.repository);

  Future<AuthResult> execute(String email, String password) async {
    return await repository.signUpWithEmail(email, password);
  }
}

/// 구글 로그인 유스케이스
class SignInWithGoogleUseCase extends AuthUseCase {
  SignInWithGoogleUseCase(super.repository);

  Future<AuthResult> execute() async {
    return await repository.signInWithGoogle();
  }
}

/// 애플 로그인 유스케이스

/// 로그아웃 유스케이스
class SignOutUseCase extends AuthUseCase {
  SignOutUseCase(super.repository);

  Future<void> execute() async {
    return await repository.signOut();
  }
}

/// 계정 삭제 유스케이스
class DeleteAccountUseCase extends AuthUseCase {
  DeleteAccountUseCase(super.repository);

  Future<void> execute() async {
    return await repository.deleteAccount();
  }
}
