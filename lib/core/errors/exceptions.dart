/// 커스텀 예외 클래스들

abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class CacheException extends AppException {
  CacheException(String message) : super(message);
}

class DatabaseException extends AppException {
  DatabaseException(String message) : super(message);
}

class CrawlingException extends AppException {
  CrawlingException(String message) : super(message);
}

class AIAnalysisException extends AppException {
  AIAnalysisException(String message) : super(message);
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}
