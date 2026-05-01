import 'dart:io';

enum TargetPlatform {
  android,
  iOS,
  fuchsia,
  linux,
  macos,
  windows,
}

const bool kIsWeb = false;
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

TargetPlatform get defaultTargetPlatform {
  try {
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.iOS;
    if (Platform.isFuchsia) return TargetPlatform.fuchsia;
    if (Platform.isMacOS) return TargetPlatform.macos;
    if (Platform.isWindows) return TargetPlatform.windows;
    return TargetPlatform.linux;
  } catch (_) {
    return TargetPlatform.linux;
  }
}

void debugPrint(String? message, {int? wrapWidth}) {
  if (message == null) {
    return;
  }
  stdout.writeln(message);
}
