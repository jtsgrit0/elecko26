import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72),
              const SizedBox(height: 16),
              const Text(
                '투표 기능은 로그인 후 이용할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                '로컬 Chrome 웹에서는 Firebase 기반 로그인 기능을 잠시 비활성화했습니다.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
