import 'dart:io';

/// CLI 환경에서의 에셋 로더 구현체 (dart:io 사용)
class AssetLoader {
  static Future<String> loadString(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    
    // assets/ 가 경로에 없는 경우 대비
    final assetsPath = path.startsWith('assets/') ? path : 'assets/$path';
    final assetsFile = File(assetsPath);
    if (await assetsFile.exists()) {
      return await assetsFile.readAsString();
    }
    
    throw FileSystemException('Asset not found in CLI mode (File search failed)', path);
  }
}
