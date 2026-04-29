/// 커스텀 예외 클래스들
library;

abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class CacheException extends AppException {
  CacheException(super.message);
}

class DatabaseException extends AppException {
  DatabaseException(super.message);
}

class CrawlingException extends AppException {
  CrawlingException(super.message);
}

class AIAnalysisException extends AppException {
  AIAnalysisException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}
