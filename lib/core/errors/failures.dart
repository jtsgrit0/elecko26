/// 실패 클래스들 (usecase 결과용)

abstract class Failure {
  final String message;
  Failure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure(String message) : super(message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure(String message) : super(message);
}

class CrawlingFailure extends Failure {
  CrawlingFailure(String message) : super(message);
}

class AIAnalysisFailure extends Failure {
  AIAnalysisFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}
