import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/injection_container.dart' as di;

Widget _buildErrorScreen(FlutterErrorDetails details) {
  final exception = details.exceptionAsString();
  final stack = details.stack?.toString() ?? 'No stack trace available.';
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '앱 실행 중 오류가 발생했습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                exception,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stack Trace',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                stack,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (details) => _buildErrorScreen(details);

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    return true;
  };

  // 의존성 주입 설정
  await di.init();

  runApp(const MyApp());
}
