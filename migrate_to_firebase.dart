import 'dart:io';

/// Firebase 마이그레이션 스크립트의 안전한 스텁입니다.
///
/// 이 워크스페이스에서는 외부 Firebase Admin SDK 의존성을 포함하지 않기 때문에,
/// 실제 데이터 이관은 별도의 Admin 환경에서 수행해야 합니다.
void main(List<String> args) {
  stdout.writeln(
    'migrate_to_firebase.dart is disabled in this workspace.',
  );
  stdout.writeln(
    'Run the migration from a separate Firebase Admin environment if needed.',
  );
}
