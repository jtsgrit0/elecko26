import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/usecases/auth_usecases.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<domain.User?>(
      stream: AuthRepositoryImpl().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Authentication error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AuthRepositoryImpl _authRepository;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final SignInWithEmailUseCase _signInWithEmailUseCase;
  late final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  late final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  late final SignInWithAppleUseCase _signInWithAppleUseCase;
  late final SignInWithFacebookUseCase _signInWithFacebookUseCase;
  late final SignInWithKakaoUseCase _signInWithKakaoUseCase;

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepositoryImpl();
    _getCurrentUserUseCase = GetCurrentUserUseCase(_authRepository);
    _signInWithEmailUseCase = SignInWithEmailUseCase(_authRepository);
    _signUpWithEmailUseCase = SignUpWithEmailUseCase(_authRepository);
    _signInWithGoogleUseCase = SignInWithGoogleUseCase(_authRepository);
    _signInWithAppleUseCase = SignInWithAppleUseCase(_authRepository);
    _signInWithFacebookUseCase = SignInWithFacebookUseCase(_authRepository);
    _signInWithKakaoUseCase = SignInWithKakaoUseCase(_authRepository);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = _isRegisterMode
          ? await _signUpWithEmailUseCase.execute(email, password)
          : await _signInWithEmailUseCase.execute(email, password);

      if (!result.isSuccess) {
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    await _performSocialLogin(_signInWithGoogleUseCase.execute);
  }

  Future<void> _signInWithApple() async {
    await _performSocialLogin(_signInWithAppleUseCase.execute);
  }

  Future<void> _signInWithFacebook() async {
    await _performSocialLogin(_signInWithFacebookUseCase.execute);
  }

  Future<void> _signInWithKakao() async {
    await _performSocialLogin(_signInWithKakaoUseCase.execute);
  }

  Future<void> _performSocialLogin(Future<domain.AuthResult> Function() loginFunction) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await loginFunction();
      if (!result.isSuccess) {
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '로그인 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Elecko 인증',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _isRegisterMode ? '새 계정을 만드시려면 아래를 입력하세요.' : '기존 계정으로 로그인하세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Text(_isRegisterMode ? '회원가입' : '로그인'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _errorMessage = null;
                    });
                  },
                  child: Text(_isRegisterMode ? '로그인으로 돌아가기' : '회원가입하기'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '또는 소셜 계정으로 로그인',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _buildSocialLoginButtons(),
              if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        _buildSocialButton(
          onPressed: _signInWithGoogle,
          icon: Icons.g_mobiledata,
          label: 'Google로 계속하기',
          color: Colors.red,
        ),
        const SizedBox(height: 8),
        _buildSocialButton(
          onPressed: _signInWithApple,
          icon: Icons.apple,
          label: 'Apple로 계속하기',
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        _buildSocialButton(
          onPressed: _signInWithFacebook,
          icon: Icons.facebook,
          label: 'Facebook으로 계속하기',
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildSocialButton(
          onPressed: _signInWithKakao,
          icon: Icons.chat,
          label: '카카오로 계속하기',
          color: Colors.yellow,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }
}
