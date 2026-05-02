import 'package:elecko26_new/domain/entities/member.dart';

// 웹 환경에서는 Isolate를 사용할 수 없으므로, 스텁 함수를 제공합니다.
// 이 함수는 웹에서 호출될 경우 UnsupportedError를 발생시키거나,
// 여기서는 아무것도 하지 않도록 처리합니다.
Future<void> calculateElectionPossibilityInIsolate(
    Map<String, dynamic> message) async {
  // 웹에서는 Isolate를 사용할 수 없으므로, 이 함수는 실제로 아무것도 하지 않습니다.
  // 필요하다면 여기에 웹 환경에 맞는 대체 로직을 구현할 수 있습니다.
  // 예를 들어, 메인 스레드에서 직접 계산을 수행하거나,
  // 웹 워커를 사용하는 등의 방법을 고려할 수 있습니다.
  // 현재는 단순히 아무것도 하지 않도록 처리하여 컴파일 오류를 방지합니다.
  // throw UnsupportedError('Isolates are not supported on the web.');
}
