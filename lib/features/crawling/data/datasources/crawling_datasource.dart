/// 크롤링 데이터 소스 추상 클래스
abstract class CrawlingDataSource {
  /// 의회 공식 웹사이트에서 국회의원 정보 크롤링
  Future<List<Map<String, dynamic>>> crawlParliamentMembers();
  
  /// 개인 웹사이트/SNS에서 정책 및 활동 크롤링
  Future<Map<String, dynamic>> crawlMemberActivity(String memberId);
  
  /// 뉴스/언론사에서 언론보도 크롤링
  Future<List<Map<String, dynamic>>> crawlPressReports(String memberId);
  
  /// 소셜 미디어에서 여론 데이터 크롤링
  Future<List<Map<String, dynamic>>> crawlSocialMedia(String memberId);
}

/// 크롤링 데이터 소스 구현체
class CrawlingDataSourceImpl implements CrawlingDataSource {
  @override
  Future<List<Map<String, dynamic>>> crawlParliamentMembers() async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> crawlMemberActivity(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> crawlPressReports(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> crawlSocialMedia(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }
}
