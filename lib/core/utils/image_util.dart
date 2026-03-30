class ImageUtil {
  /// 외부 이미지 URL을 프록시(wsrv.nl) URL로 변환하여 CORS 이슈를 회피합니다.
  static String getProxyUrl(String url) {
    if (url.isEmpty) return url;
    
    // 나무위키나 위키미디어 등 외부 호출을 제한하는 도메인에 대해 프록시 적용
    if (url.contains('namu.wiki') || url.contains('wikimedia.org')) {
      //wsrv.nl 프록시 서비스 사용
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
    }
    
    return url;
  }
}
