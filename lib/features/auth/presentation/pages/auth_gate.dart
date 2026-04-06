import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 웹에서는 Firebase 없이 바로 홈으로 이동
    if (kIsWeb) {
      return const HomePage();
    }

    // 모바일에서는 기존 인증 로직 사용 (Firebase 필요)
    return const Scaffold(
      body: Center(
        child: Text('모바일 인증은 Firebase가 필요합니다. 웹에서 사용하세요.'),
      ),
    );
  }
}
