import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';

void main() async {
  await init(); // 의존성 주입 초기화
  final memberRepository = sl<MemberRepository>();
  await memberRepository.clearAllMembers();
  print('모든 후보자 데이터가 성공적으로 삭제되었습니다.');
}
