/// 네트워크 관련 유틸리티
class NetworkUtil {
  static const String baseUrl = 'https://api.example.com';
  
  /// URL이 유효한지 확인
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// HTTP 상태 코드 검증
  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}

/// 날짜 유틸리티
class DateUtil {
  /// 날짜를 한국식 형식으로 포맷
  static String formatKorean(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
  
  /// 날짜 차이 계산 (일 단위)
  static int daysDifference(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }
  
  /// 오늘 날짜
  static DateTime get today => DateTime.now();
  
  /// 어제 날짜
  static DateTime get yesterday => DateTime.now().subtract(const Duration(days: 1));
}

/// 문자열 유틸리티
class StringUtil {
  /// 문자열이 빈 값인지 확인
  static bool isEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }
  
  /// 문자열 길이 제한
  static String limitLength(String str, int maxLength) {
    if (str.length > maxLength) {
      return '${str.substring(0, maxLength)}...';
    }
    return str;
  }
}

/// 숫자 유틸리티
class NumberUtil {
  /// 백분율 형식으로 변환
  static String toPercentage(double value, {int decimal = 1}) {
    return '${(value * 100).toStringAsFixed(decimal)}%';
  }
  
  /// 숫자를 소수점 자릿수로 포맷
  static String formatDecimal(double value, {int decimal = 2}) {
    return value.toStringAsFixed(decimal);
  }
  
  /// 백만 단위 이상의 숫자를 약자로 표시
  static String formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
