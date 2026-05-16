class ImageUtil {
  /// 외부 이미지 URL을 프록시(wsrv.nl) URL로 변환하여 CORS 이슈를 회피하고 이미지를 최적화합니다.
  /// [width], [height]가 지정되면 해당 크기로 리사이징하며, 기본적으로 WebP 형식으로 변환합니다.
  static String getProxyUrl(String url, {int? width, int? height}) {
    if (url.isEmpty) return url;
    if (url.startsWith('assets/')) return url;

    // 모든 외부 이미지에 대해 프록시 적용 (CORS 및 리사이징)
    final encodedUrl = Uri.encodeComponent(url);
    // 강제 WebP 변환 옵션을 제거하여 안정성 확보 (PNG 등 포맷 존중)
    String proxyUrl = 'https://wsrv.nl/?url=$encodedUrl';

    if (width != null) {
      proxyUrl += '&w=$width';
    }
    if (height != null) {
      proxyUrl += '&h=$height';
    }

    // 리사이징 시 이미지가 잘리지 않도록 cover fit 적용
    if (width != null || height != null) {
      proxyUrl += '&fit=cover';
    }

    return proxyUrl;
  }
}
