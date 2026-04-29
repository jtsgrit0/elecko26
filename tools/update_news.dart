import 'dart:io';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:elecko26_new/data/firebase_options.dart';

/// 모든 후보자의 최신 뉴스를 크롤링하여 Firestore에 업데이트하는 스크립트
Future<void> main() async {
  print('[NewsUpdater] 뉴스 업데이트 스크립트를 시작합니다...');

  // Firebase 및 의존성 주입 초기화
  await _initialize();

  try {
    final memberRepository = di.sl<MemberRepository>();

    // MemberRepository에 모든 후보자 뉴스 업데이트를 요청하는 새로운 메서드를 호출할 예정입니다.
    // (이 메서드는 다음 단계에서 구현합니다.)
    await memberRepository.crawlNewsForAllMembers();

    print('[NewsUpdater] 모든 후보자의 뉴스 업데이트가 성공적으로 완료되었습니다.');
  } catch (e) {
    print('[NewsUpdater] 뉴스 업데이트 중 오류가 발생했습니다: $e');
    exit(1); // 오류 발생 시 비정상 종료
  }

  exit(0); // 정상 종료
}

Future<void> _initialize() async {
  print('[NewsUpdater] Firebase 및 의존성 주입을 초기화합니다...');
  // 스크립트 환경에서 Firebase를 초기화하기 위해 별도 설정이 필요합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();
  print('[NewsUpdater] 초기화가 완료되었습니다.');
}
