/// 크롤링 UseCase
abstract class CrawlMemberDataUseCase {
  /// 모든 의원 정보 크롤링
  Future<void> crawlAllMembers();
  
  /// 특정 의원의 활동 정보 크롤링
  Future<void> crawlMemberActivity(String memberId);
  
  /// 언론 보도 크롤링
  Future<void> crawlPressReports(String memberId);
  
  /// 소셜 미디어 여론 수집
  Future<void> crawlSocialMedia(String memberId);
  
  /// 정기적 업데이트
  Future<void> scheduledUpdate();
}

/// CrawlMemberDataUseCase 구현체
class CrawlMemberDataUseCaseImpl implements CrawlMemberDataUseCase {
  @override
  Future<void> crawlAllMembers() async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<void> crawlMemberActivity(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<void> crawlPressReports(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<void> crawlSocialMedia(String memberId) async {
    // TODO: 구현
    throw UnimplementedError();
  }

  @override
  Future<void> scheduledUpdate() async {
    // TODO: 구현
    throw UnimplementedError();
  }
}
