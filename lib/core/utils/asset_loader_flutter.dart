import 'package:flutter/services.dart' show rootBundle;

/// Flutter 환경에서의 에셋 로더 구현체 (rootBundle 사용)
class AssetLoader {
  static Future<String> loadString(String path) async {
    return await rootBundle.loadString(path);
  }
}
