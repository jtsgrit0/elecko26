import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/firebase_options.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 모든 후보자의 최신 뉴스를 크롤링하여 Firestore에 업데이트하는 스크립트
Future<void> main() async {
  // 스크립트가 Flutter 엔진과 상호작용할 수 있도록 바인딩을 초기화합니다.
  // WidgetsFlutterBinding.ensureInitialized();

  // Firebase를 명시적으로 초기화하고 완료될 때까지 기다립니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 의존성 주입 초기화
  await di.init();

  print('[NewsUpdater] 뉴스 업데이트 스크립트를 시작합니다...');

  try {
    final memberRepository = di.sl<MemberRepository>();
    await memberRepository.crawlNewsForAllMembers();
    print('[NewsUpdater] 모든 후보자의 뉴스 업데이트가 성공적으로 완료되었습니다.');
  } catch (e) {
    print('[NewsUpdater] 뉴스 업데이트 중 오류가 발생했습니다: $e');
  } finally {
    // 스크립트가 끝나면 프로세스를 종료합니다.
    // 약간의 딜레이를 주어 모든 비동기 작업이 완료될 시간을 확보합니다.
    await Future.delayed(const Duration(seconds: 2));
    SystemNavigator.pop();
  }
}
