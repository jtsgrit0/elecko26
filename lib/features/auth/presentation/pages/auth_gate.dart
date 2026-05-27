import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/features/auth/domain/usecases/auth_usecases.dart';
import 'package:elecko26_new/features/auth/presentation/widgets/terms_agreement_modal.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await sl<SignInWithGoogleUseCase>().execute();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _message = result.isSuccess ? null : (result.errorMessage ?? '로그인 실패');
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleEmailSignIn({required bool signUp}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = '이메일과 비밀번호를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = signUp
        ? await sl<SignUpWithEmailUseCase>().execute(email, password)
        : await sl<SignInWithEmailUseCase>().execute(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _message = result.isSuccess ? null : (result.errorMessage ?? '로그인 실패');
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _showTerms() async {
    await TermsAgreementModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.verified_user, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              '당예기 계정으로 로그인',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 8),
            Text(
              '후보 즐겨찾기와 투표 기능을 사용하려면 로그인이 필요합니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkGray),
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
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : () => _handleEmailSignIn(signUp: false),
              child: const Text('이메일 로그인'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isLoading ? null : () => _handleEmailSignIn(signUp: true),
              child: const Text('이메일 회원가입'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              child: const Text('Google로 계속하기'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _showTerms,
              child: const Text('약관 보기'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('게스트로 계속'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
