import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // SingleTickerProviderStateMixin 추가
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 애니메이션 지속 시간
    )..repeat(reverse: true); // 줌인/줌아웃을 위해 반복 및 역방향 재생

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      // 0.8배에서 1.2배로 스케일 변경
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, // 부드러운 애니메이션 효과
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // 컨트롤러 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          // ScaleTransition 위젯으로 이미지 감싸기
          scale: _scaleAnimation,
          child: Image.asset(
            // Lottie.asset 대신 Image.asset 사용
            'assets/images/election_icon.png', // 이미지 경로 설정
            width: 200, // 필요에 따라 크기 조절
            height: 200, // 필요에 따라 크기 조절
          ),
        ),
      ),
    );
  }
}
