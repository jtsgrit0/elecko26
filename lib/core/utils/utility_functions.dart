import 'package:characters/characters.dart';

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
  static DateTime get yesterday =>
      DateTime.now().subtract(const Duration(days: 1));
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

/// 시간 상세 포맷
String formatRelativeTime(DateTime date) {
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min:$s';
}

/// 이름 첫 글자 추출
String getProfileInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.characters.first;
}

/// 지역명 매칭 유틸리티
///
/// 저장된 지역명(예: 충청북도/전북특별자치도)과 실제 district 문자열(예: 충북 청주시장)을
/// 안정적으로 매칭하기 위해 약칭/정식명/행정명 변형을 함께 비교합니다.
bool districtMatchesRegion(String district, String region) {
  if (region == '전국') return true;

  final normalizedDistrict = district.replaceAll(' ', '');
  for (final keyword in _regionKeywords(region)) {
    if (normalizedDistrict.contains(keyword)) return true;
  }
  return false;
}

List<String> _regionKeywords(String region) {
  const aliases = <String, List<String>>{
    '서울특별시': ['서울특별시', '서울'],
    '부산광역시': ['부산광역시', '부산'],
    '대구광역시': ['대구광역시', '대구'],
    '인천광역시': ['인천광역시', '인천'],
    '광주광역시': ['광주광역시', '광주'],
    '대전광역시': ['대전광역시', '대전'],
    '울산광역시': ['울산광역시', '울산'],
    '세종특별자치시': ['세종특별자치시', '세종'],
    '경기도': ['경기도', '경기'],
    '강원도': ['강원도', '강원'],
    '충청북도': ['충청북도', '충북'],
    '충청남도': ['충청남도', '충남'],
    '전라북도': ['전라북도', '전북'],
    '전북특별자치도': ['전북특별자치도', '전라북도', '전북'],
    '전라남도': ['전라남도', '전남'],
    '경상북도': ['경상북도', '경북'],
    '경상남도': ['경상남도', '경남'],
    '제주특별자치도': ['제주특별자치도', '제주도', '제주'],
  };

  final regionAliases = aliases[region];
  if (regionAliases != null) return regionAliases;

  // 알 수 없는 형식은 원문과 앞 2글자를 함께 비교
  final fallback = <String>[region];
  if (region.length >= 2) fallback.add(region.substring(0, 2));
  return fallback;
}
