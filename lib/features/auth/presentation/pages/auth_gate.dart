import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/injection_container.dart';
import 'package:flutter_application_1/features/auth/domain/entities/user.dart';
import 'package:flutter_application_1/features/auth/domain/usecases/auth_usecases.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = _isLoginMode
        ? await sl<SignInWithEmailUseCase>().execute(email, password)
        : await sl<SignUpWithEmailUseCase>().execute(email, password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = result.errorMessage;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitSocialLogin(Future<AuthResult> Function() action) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await action();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = result.errorMessage;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? '이메일 로그인' : '이메일 회원가입'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    _isLoginMode ? '로그인 후 계속 진행할 수 있습니다.' : '간단한 이메일 계정을 만든 뒤 계속할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return '이메일을 입력해주세요.';
                      if (!text.contains('@')) return '유효한 이메일 형식을 입력해주세요.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return '비밀번호를 입력해주세요.';
                      if (!_isLoginMode && text.length < 6) return '비밀번호는 6자 이상이어야 합니다.';
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting ? '처리 중...' : (_isLoginMode ? '로그인' : '회원가입'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('소셜 로그인'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitSocialLogin(
                              () => sl<SignInWithGoogleUseCase>().execute(),
                            ),
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('구글로 계속하기'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitSocialLogin(
                              () => sl<SignInWithAppleUseCase>().execute(),
                            ),
                    icon: const Icon(Icons.apple),
                    label: const Text('애플로 계속하기'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitSocialLogin(
                              () => sl<SignInWithFacebookUseCase>().execute(),
                            ),
                    icon: const Icon(Icons.facebook),
                    label: const Text('페이스북으로 계속하기'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitSocialLogin(
                              () => sl<SignInWithKakaoUseCase>().execute(),
                            ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('카카오로 계속하기'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                              _errorMessage = null;
                            });
                          },
                    child: Text(
                      _isLoginMode ? '계정이 없나요? 회원가입' : '이미 계정이 있나요? 로그인',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
