import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/features/auth/domain/usecases/auth_usecases.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';
import 'package:elecko26_new/features/auth/presentation/widgets/terms_agreement_modal.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart';

class AuthGate extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool isEmbedded;

  const AuthGate({
    Key? key,
    this.onSuccess,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  bool _autoLogin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAutoLoginSetting();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoLoginSetting() async {
    final localService = sl<LocalStorageService>();
    final saved = await localService.getString('auto_login') == 'true';
    if (saved && mounted) {
      setState(() {
        _autoLogin = true;
      });
      // 저장된 이메일/비밀번호가 있으면 자동 로그인 시도
      final savedEmail = await localService.getString('auto_login_email');
      final savedPassword = await localService.getString('auto_login_password');
      if (savedEmail != null && savedPassword != null && savedEmail.isNotEmpty && mounted) {
        // 자동 로그인 전 Firebase 세션 초기화 (이전 프로젝트 캐시 제거)
        try {
          await auth.FirebaseAuth.instance.signOut();
        } catch (_) {}
        
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _submit();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 회원가입 모드일 때 약관 동의 모달 먼저 표시
    if (!_isLoginMode) {
      final agreed = await TermsAgreementModal.show(context);
      if (!agreed || !mounted) return;
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
      // 자동 로그인 체크 시 이메일/비밀번호 저장
      if (_autoLogin && _isLoginMode) {
        final localService = sl<LocalStorageService>();
        await localService.setString('auto_login', 'true');
        await localService.setString('auto_login_email', email);
        await localService.setString('auto_login_password', password);
      } else {
        final localService = sl<LocalStorageService>();
        await localService.setString('auto_login', 'false');
        await localService.setString('auto_login_email', '');
        await localService.setString('auto_login_password', '');
      }

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _submitSocialLogin(Future<AuthResult> Function() action) async {
    // 회원가입 모드일 때 약관 동의 모달 먼저 표시
    if (!_isLoginMode) {
      final agreed = await TermsAgreementModal.show(context);
      if (!agreed || !mounted) return;
    }

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
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _showSocialLoginNotice() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('웹 안정화 중이라 현재는 이메일 로그인만 지원합니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6E6D8),
              Color(0xFFF8F4EE),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.isEmbedded) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('돌아가기'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7B241C),
                            Color(0xFFB03A2E),
                            Color(0xFFD35400),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331F1F1F),
                            blurRadius: 30,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.how_to_vote_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'ELECTION ACCESS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isLoginMode ? '투표 참여를\n계속하려면 로그인하세요' : '계정을 만들고\n바로 투표에 참여하세요',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isLoginMode
                                ? '관심 있는 의제에 의견을 남기고, 프로필과 투표 기능을 함께 사용할 수 있습니다.'
                                : '이메일 또는 소셜 계정으로 빠르게 시작하고, 투표와 프로필 기능을 바로 이용할 수 있습니다.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE9DED2)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x141B1B1B),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _isLoginMode ? '이메일 로그인' : '새 계정 만들기',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9EEE4),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _isLoginMode ? 'EMAIL' : 'SIGN UP',
                                    style: const TextStyle(
                                      color: Color(0xFF9A3412),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLoginMode
                                  ? '이미 계정이 있다면 이메일과 비밀번호로 바로 로그인하세요.'
                                  : '간단한 계정을 만들고 투표와 프로필 기능을 바로 사용할 수 있습니다.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: '이메일',
                                prefixIcon: const Icon(Icons.alternate_email_rounded),
                                filled: true,
                                fillColor: const Color(0xFFFCF8F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return '이메일을 입력해주세요.';
                                if (!text.contains('@')) return '유효한 이메일 형식을 입력해주세요.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                filled: true,
                                fillColor: const Color(0xFFFCF8F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                final text = value ?? '';
                                if (text.isEmpty) return '비밀번호를 입력해주세요.';
                                if (!_isLoginMode && text.length < 6) return '비밀번호는 6자 이상이어야 합니다.';
                                return null;
                              },
                            ),
                            if (_isLoginMode) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _autoLogin,
                                      onChanged: (value) {
                                        setState(() {
                                          _autoLogin = value ?? false;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _autoLogin = !_autoLogin;
                                      });
                                    },
                                    child: const Text(
                                      '자동 로그인',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFDA4AF)),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9A3412),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  _isSubmitting ? '처리 중...' : (_isLoginMode ? '이메일로 로그인' : '이메일로 시작하기'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '소셜 로그인',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildSocialAction(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  color: const Color(0xFFDB4437),
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _submitSocialLogin(sl<SignInWithGoogleUseCase>().execute),
                                ),
                                if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS))
                                  _buildSocialAction(
                                    label: 'Apple',
                                    icon: Icons.apple_rounded,
                                    color: Colors.black87,
                                    onTap: _isSubmitting
                                        ? null
                                        : () => _submitSocialLogin(sl<SignInWithAppleUseCase>().execute),
                                  ),
                                _buildSocialAction(
                                  label: 'Facebook',
                                  icon: Icons.facebook_rounded,
                                  color: const Color(0xFF1877F2),
                                  onTap: _isSubmitting
                                      ? null
                                      : _showSocialLoginNotice,
                                ),
                                _buildSocialAction(
                                  label: 'Kakao',
                                  icon: Icons.chat_bubble_rounded,
                                  color: const Color(0xFFFEE500),
                                  foreground: Colors.black87,
                                  onTap: _isSubmitting
                                      ? null
                                      : _showSocialLoginNotice,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
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
                                _isLoginMode ? '계정이 없나요? 회원가입으로 전환' : '이미 계정이 있나요? 로그인으로 전환',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    Color foreground = Colors.white,
  }) {
    return SizedBox(
      width: 194,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foreground, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
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
