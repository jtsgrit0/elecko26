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

  // 1. district에서 상위 지역 추출 시도 (예: "종로구청장" -> "서울특별시")
  final parentRegion = getParentRegion(district);
  if (parentRegion == region) return true;

  // 2. getParentRegion으로도 매칭되지 않은 경우에만 텍스트 포함 매칭 시도
  // 이미 매핑 테이블에 있는 지역은 정확히 매칭되도록 함
  if (parentRegion.isEmpty) {
    // 텍스트 포함 여부로 매칭 (fallback)
    final normalizedDistrict = district.replaceAll(' ', '');
    for (final keyword in _regionKeywords(region)) {
      if (normalizedDistrict.contains(keyword)) return true;
    }
  }

  return false;
}

/// district 명칭에서 상위 광역 단위 지역명을 추출합니다.
/// 예: "서울특별시장" -> "서울특별시", "연수구청장" -> "인천광역시"
String getParentRegion(String district) {
  // 매핑 테이블 (하위 지명 -> 상위 광역 단위)
  const districtToRegion = <String, String>{
    // 1순위: 광역 지자체명 (우선순위 높음)
    '서울특별시': '서울특별시', '서울': '서울특별시',
    '부산광역시': '부산광역시', '부산': '부산광역시',
    '대구광역시': '대구광역시', '대구': '대구광역시',
    '인천광역시': '인천광역시', '인천': '인천광역시',
    '광주광역시': '광주광역시', '광주': '광주광역시',
    '대전광역시': '대전광역시', '대전': '대전광역시',
    '울산광역시': '울산광역시', '울산': '울산광역시',
    '세종특별자치시': '세종특별자치시', '세종': '세종특별자치시',
    '경기도': '경기도', '경기': '경기도',
    '강원특별자치도': '강원도', '강원도': '강원도', '강원': '강원도',
    '충청북도': '충청북도', '충북': '충청북도',
    '충청남도': '충청남도', '충남': '충청남도',
    '전북특별자치도': '전라북도', '전라북도': '전라북도', '전북': '전라북도',
    '전라남도': '전라남도', '전남': '전라남도',
    '경상북도': '경상북도', '경북': '경상북도',
    '경상남도': '경상남도', '경남': '경상남도',
    '제주특별자치도': '제주특별자치도', '제주도': '제주특별자치도', '제주': '제주특별자치도',

    // 2순위: 고유한 기초 지자체명
    // 서울
    '종로': '서울특별시', '용산': '서울특별시', '성동': '서울특별시', '광진': '서울특별시',
    '동대문': '서울특별시', '중랑': '서울특별시', '성북': '서울특별시', '강북': '서울특별시', '도봉': '서울특별시',
    '노원': '서울특별시', '은평': '서울특별시', '서대문': '서울특별시', '마포': '서울특별시', '양천': '서울특별시',
    '강서구': '서울특별시', // 강서는 부산에도 있으나 서울 강서구가 더 빈번함
    '구로': '서울특별시', '금천': '서울특별시', '영등포': '서울특별시', '동작': '서울특별시',
    '관악': '서울특별시', '서초': '서울특별시', '강남': '서울특별시', '송파': '서울특별시', '강동': '서울특별시',

    // 부산
    '해운대': '부산광역시', '영도': '부산광역시', '연제': '부산광역시', '수영': '부산광역시', '기장': '부산광역시',
    '부산진': '부산광역시', '동래': '부산광역시', '금정': '부산광역시', '사하': '부산광역시', '사상': '부산광역시',

    // 대구
    '수성': '대구광역시', '달서': '대구광역시', '달성': '대구광역시', '군위': '대구광역시',

    // 인천
    '연수': '인천광역시', '남동': '인천광역시', '부평': '인천광역시', '강화': '인천광역시',
    '계양': '인천광역시', '미추홀': '인천광역시', '옹진': '인천광역시',

    // 광주
    '광산': '광주광역시',

    // 경기도
    '수원': '경기도', '용인': '경기도', '고양': '경기도', '화성': '경기도', '성남': '경기도',
    '부천': '경기도', '남양주': '경기도', '안산': '경기도', '평택': '경기도', '안양': '경기도',
    '시흥': '경기도',
    '파주': '경기도', '김포': '경기도', '의정부': '경기도', '하남': '경기도', '군포': '경기도',
    '오산': '경기도',

    // 기타 주요 도시
    '청주': '충청북도', '충주': '충청북도', '제천': '충청북도',
    '천안': '충청남도', '아산': '충청남도', '논산': '충청남도', '당진': '충청남도', '공주': '충청남도',
    '전주': '전라북도', '익산': '전라북도', '군산': '전라북도',
    '목포': '전라남도', '여수': '전라남도', '순천': '전라남도', '나주': '전라남도', '광양': '전라남도',
    '포항': '경상북도', '구미': '경상북도', '경주': '경상북도', '안동': '경상북도', '경산': '경상북도',
    '창원': '경상남도', '김해': '경상남도', '진주': '경상남도', '거제': '경상남도',

    // 3순위: 중복 가능성이 높은 지명 (fallback용)
    // 이들은 광역 지명이 없을 때만 매칭되도록 후순위에 배치
    '남구': '대구광역시', '북구': '대구광역시', '서구': '대구광역시', '동구': '대구광역시', '중구': '대구광역시',
  };

  // 정확한 매칭을 위해 긴 키워드부터 검사 (예: "해운대"가 "남구"보다 먼저 매칭되도록)
  final sortedEntries = districtToRegion.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  for (final entry in sortedEntries) {
    if (district.contains(entry.key)) {
      return entry.value;
    }
  }

  return '';
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

/// 선거구 명칭별 정렬 우선순위를 반환합니다. (낮을수록 상단)
/// 사용 요청 순서: 도지사 > 시장 > 구의원 > 군수 > 군의원
int getDistrictSortPriority(String district) {
  // 1순위: 광역단체장 (도지사, 특별시장, 광역시장 등)
  if (district.contains('도지사') ||
      district.contains('특별시장') ||
      district.contains('광역시장') ||
      district.contains('자치시장')) {
    return 1;
  }

  // 2순위: 기초단체장 (시장, 구청장) - 군수는 사용자 요청에 따라 뒤로 밀림
  if (district.contains('시장') || district.contains('구청장')) {
    return 2;
  }

  // 3순위: 구의원
  if (district.contains('구의원')) {
    return 3;
  }

  // 4순위: 군수
  if (district.contains('군수')) {
    return 4;
  }

  // 5순위: 군의원
  if (district.contains('군의원')) {
    return 5;
  }

  // 6순위: 시의원, 도의원 등 기타 의원
  if (district.contains('의원')) {
    return 6;
  }

  return 99; // 기타
}
