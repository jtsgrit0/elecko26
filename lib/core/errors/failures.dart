/// 실패 클래스들 (usecase 결과용)
library;

abstract class Failure {
  final String message;
  Failure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure(super.message);
}

class CrawlingFailure extends Failure {
  CrawlingFailure(super.message);
}

class AIAnalysisFailure extends Failure {
  AIAnalysisFailure(super.message);
}

class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}
