import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // Firebase 초기화 (모바일/데스크톱만)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firebase 플러그인 인스턴스 로드
    FirebaseAuth.instance;
    FirebaseFirestore.instance;
  }

  // 의존성 주입 설정
  await di.init();

  runApp(const MyApp());
}