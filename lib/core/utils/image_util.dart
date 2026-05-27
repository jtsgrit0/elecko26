import 'image_utils.dart';

/// 이전 `ImageUtil` 호출부와의 호환성을 위한 얇은 래퍼입니다.
class ImageUtil {
  static String getProxyUrl(String url, {int? width, int? height}) {
    return ImageUtils.getProxyUrl(url, width: width, height: height);
  }
}
