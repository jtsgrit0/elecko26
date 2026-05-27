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
class DateTimeUtils {
  /// 날짜를 한국식 형식으로 포맷
  static String formatKorean(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// 일반적인 날짜 표기 포맷
  ///
  /// 연도 정보가 비어 있거나 기본값(1900년대)인 경우에는 정보 없음으로 처리합니다.
  static String formatDate(DateTime date) {
    if (date.year <= 1900) {
      return '정보 없음';
    }
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

/// 지역명 또는 선거구명에서 정규화된 키워드 목록을 추출합니다.
/// 다양한 형태의 지역명을 통일된 키워드로 변환하여 매칭의 정확도를 높입니다.
List<String> _getNormalizedRegionKeywords(String name) {
  final normalizedName = name.replaceAll(' ', '');
  final keywords = <String>{};

  if (normalizedName.isEmpty) return keywords.toList();

  // 1. 원본 이름 및 정규화된 이름 추가
  keywords.add(normalizedName);

  // 2. 특별/광역시 축약형 추가 (예: "서울" -> "서울특별시")
  const shortForms = {
    '서울': '서울특별시',
    '부산': '부산광역시',
    '대구': '대구광역시',
    '인천': '인천광역시',
    '광주': '광주광역시',
    '대전': '대전광역시',
    '울산': '울산광역시',
    '세종': '세종특별자치시',
    '경기': '경기도',
    '강원': '강원특별자치도',
    '충북': '충청북도',
    '충남': '충청남도',
    '전북': '전북특별자치도',
    '전남': '전라남도',
    '경북': '경상북도',
    '경남': '경상남도',
    '제주': '제주특별자치도',
  };
  shortForms.forEach((short, full) {
    if (normalizedName.contains(short) &&
        normalizedName.length <= full.length + 2) {
      // 짧은 이름이 포함되고 길이가 크게 차이나지 않을 때
      keywords.add(short);
      keywords.add(full);
    }
    if (normalizedName.contains(full)) {
      keywords.add(short);
      keywords.add(full);
    }
  });

  // 3. getParentRegion을 통해 상위 지역명 추가
  final parentRegion = getParentRegion(name);
  if (parentRegion.isNotEmpty) {
    keywords.add(parentRegion.replaceAll(' ', ''));
    // 상위 지역의 축약형도 추가
    shortForms.forEach((short, full) {
      if (parentRegion == full) {
        keywords.add(short);
      }
    });
  }

  // 4. 특정 접미사 제거 (예: "시장", "구청장", "의원")
  final suffixesToRemove = ['시장', '구청장', '군수', '의원', '도지사'];
  String cleanedName = normalizedName;
  for (final suffix in suffixesToRemove) {
    if (cleanedName.endsWith(suffix)) {
      cleanedName =
          cleanedName.substring(0, cleanedName.length - suffix.length);
      keywords.add(cleanedName);
    }
  }

  // 5. "시", "도", "구", "군" 등의 행정구역 단위 제거
  final adminUnitsToRemove = ['시', '도', '구', '군'];
  String nameWithoutAdminUnits = normalizedName;
  for (final unit in adminUnitsToRemove) {
    if (nameWithoutAdminUnits.endsWith(unit)) {
      nameWithoutAdminUnits = nameWithoutAdminUnits.substring(
          0, nameWithoutAdminUnits.length - unit.length);
      keywords.add(nameWithoutAdminUnits);
    }
  }

  return keywords.where((k) => k.isNotEmpty).toSet().toList();
}

/// 지역명 매칭 유틸리티
///
/// 저장된 지역명(예: 충청북도/전북특별자치도)과 실제 district 문자열(예: 충북 청주시장)을
/// 안정적으로 매칭하기 위해 약칭/정식명/행정명 변형을 함께 비교합니다.
bool districtMatchesRegion(String district, String region) {
  if (region == '전국') return true;

  final districtKeywords = _getNormalizedRegionKeywords(district);
  final regionKeywords = _getNormalizedRegionKeywords(region);

  // 두 키워드 집합 사이에 공통된 요소가 있는지 확인
  for (final dKeyword in districtKeywords) {
    for (final rKeyword in regionKeywords) {
      if (dKeyword == rKeyword ||
          dKeyword.contains(rKeyword) ||
          rKeyword.contains(dKeyword)) {
        return true;
      }
    }
  }

  return false;
}

/// district 명칭에서 상위 광역 단위 지역명을 추출합니다.
/// 예: "서울특별시장" -> "서울특별시", "연수구청장" -> "인천광역시"
String getParentRegion(String district) {
  final normalized = district.replaceAll(' ', '');
  if (normalized.isEmpty) {
    return '';
  }

  const regionAliases = <String, List<String>>{
    '서울특별시': ['서울특별시', '서울'],
    '부산광역시': ['부산광역시', '부산'],
    '대구광역시': ['대구광역시', '대구'],
    '인천광역시': ['인천광역시', '인천'],
    '광주광역시': ['광주광역시', '광주'],
    '대전광역시': ['대전광역시', '대전'],
    '울산광역시': ['울산광역시', '울산'],
    '세종특별자치시': ['세종특별자치시', '세종'],
    '경기도': ['경기도', '경기'],
    '강원특별자치도': ['강원특별자치도', '강원도', '강원'],
    '충청북도': ['충청북도', '충북'],
    '충청남도': ['충청남도', '충남'],
    '전북특별자치도': ['전북특별자치도', '전라북도', '전북'],
    '전라북도': ['전라북도', '전북'],
    '전라남도': ['전라남도', '전남'],
    '경상북도': ['경상북도', '경북'],
    '경상남도': ['경상남도', '경남'],
    '제주특별자치도': ['제주특별자치도', '제주도', '제주'],
  };

  for (final entry in regionAliases.entries) {
    for (final alias in entry.value) {
      if (normalized.contains(alias.replaceAll(' ', ''))) {
        return entry.key;
      }
    }
  }

  if (normalized.contains('전국')) {
    return '전국';
  }

  return district;
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
