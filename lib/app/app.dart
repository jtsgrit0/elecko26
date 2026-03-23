import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2026 지방선거 - 국회의원 AI 분석',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
      // 라우트 설정
      // routes: {
      //   '/': (context) => const HomePage(),
      //   '/member': (context) => const MemberDetailPage(),
      //   '/analysis': (context) => const AnalysisPage(),
      // },
    );
  }
}
