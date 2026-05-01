import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('후보 데이터가 8000명 이상 로드된다', () async {
    await initMinimal();

    final members = await sl<MemberRepository>().getAllMembers();

    expect(members.length, greaterThanOrEqualTo(8000));
  });
}
