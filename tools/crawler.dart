import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

/// 다중 소스(네이버, 다음, 구글, 위키백과 등)를 검색하여
/// 2026 지방선거 출마 관련 데이터를 추출하고 저장하는 스크립트입니다.
void main() async {
  print('🚀 다중 소스 크롤링을 시작합니다: 2026 지방선거 후보자 발굴');

  final List<String> searchQueries = [
    '2026 지방선거 출마',
    '2026 지방선거 예비후보',
    '2026 지방선거 공천',
    '2026 지방선거 경선',
    '지방선거 차출론',
    '지방선거 유력 후보',
    '서울시장 후보군',
    '경기도지사 후보군',
    '인천시장 후보군',
    '부산시장 후보군',
    '제주도지사 후보군',
    '구청장 출마 선언',
    '시장 후보 물망',
  ];

  // SNS 검색용 쿼리 (특정 사이트 타겟팅)
  final List<String> snsQueries = [
    'site:twitter.com "지방선거" "출마" 2026',
    'site:facebook.com "지방선거" "공천" 2026',
    'site:instagram.com "지방선거" "예비후보" 2026',
    'site:blog.naver.com "지방선거" "차출" 2026',
    'site:youtube.com "지방선거" "출마 선언" 2026',
  ];

  List<Map<String, dynamic>> allCandidates = [];

  // 1. 일반 뉴스 및 포털 검색
  for (final query in searchQueries) {
    print('🔍 포털 검색 중: $query');
    final naverResults = await crawlNaver(query);
    final daumResults = await crawlDaum(query);
    allCandidates.addAll(naverResults);
    allCandidates.addAll(daumResults);
    await Future.delayed(Duration(milliseconds: 500));
  }

  // 2. 구글 및 SNS 검색 (인덱싱된 게시물 위주)
  for (final query in snsQueries) {
    print('🔍 구글/SNS 검색 중: $query');
    final googleResults = await crawlGoogle(query);
    allCandidates.addAll(googleResults);
    await Future.delayed(Duration(milliseconds: 800));
  }

  // 3. 중복 제거 및 데이터 통합 (이름 기준)
  final uniqueCandidatesMap = <String, Map<String, dynamic>>{};
  for (final c in allCandidates) {
    final name = c['name'] as String;
    if (!uniqueCandidatesMap.containsKey(name)) {
      uniqueCandidatesMap[name] = c;
    } else {
      // 기존 데이터에 정보 병합 (이미지, 보도자료 등)
      _mergeCandidateData(uniqueCandidatesMap[name]!, c);
    }
  }

  // 4. 발굴된 인물들에 대해 위키백과/나무위키 정밀 검색 및 데이터 보강
  print('📚 위키 데이터 기반 후보자 정보 보강 중...');
  for (final name in uniqueCandidatesMap.keys) {
    final wikiBio = await fetchWikipediaBio(name);
    if (wikiBio != null && wikiBio.isNotEmpty) {
      uniqueCandidatesMap[name]!['bio'] = wikiBio;
    }
  }

  final finalCandidates = uniqueCandidatesMap.values.toList();

  // 5. 파일 저장 로직
  await _saveCandidatesToFile(finalCandidates);
}

/// 네이버 뉴스 크롤링
Future<List<Map<String, dynamic>>> crawlNaver(String query) async {
  final url =
      'https://search.naver.com/search.naver?where=news&query=${Uri.encodeComponent(query)}';
  return _crawlPortalNews(url, sourceName: 'Naver');
}

/// 다음 뉴스 크롤링
Future<List<Map<String, dynamic>>> crawlDaum(String query) async {
  final url =
      'https://search.daum.net/search?w=news&q=${Uri.encodeComponent(query)}';
  return _crawlPortalNews(url, sourceName: 'Daum');
}

/// 구글 검색 크롤링 (SNS 등 포함)
Future<List<Map<String, dynamic>>> crawlGoogle(String query) async {
  final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
  try {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    });
    if (response.statusCode != 200) return [];

    final document = parse(response.body);
    final results = <Map<String, dynamic>>[];

    // 구글 검색 결과 제목 추출 (보통 h3 태그)
    final titles = document.querySelectorAll('h3');
    for (final titleElement in titles) {
      final title = titleElement.text.trim();
      final name = _extractNameFromTitle(title);
      if (name != null) {
        results.add(_createCandidateTemplate(name, title, 'Google Search', ''));
      }
    }
    return results;
  } catch (e) {
    print('❌ 구글 검색 실패: $e');
    return [];
  }
}

/// 위키백과 API를 통한 데이터 보강
Future<String?> fetchWikipediaBio(String name) async {
  try {
    final url =
        'https://ko.wikipedia.org/w/api.php?action=query&prop=extracts&exintro&explaintext&titles=${Uri.encodeComponent(name)}&format=json&origin=*';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final pages = data['query']['pages'] as Map<String, dynamic>;
      final pageId = pages.keys.first;
      if (pageId != '-1') {
        return pages[pageId]['extract'];
      }
    }
  } catch (e) {
    print('⚠️ 위키백과 검색 실패 ($name): $e');
  }
  return null;
}

/// 포털 뉴스 크롤링 공통 로직
Future<List<Map<String, dynamic>>> _crawlPortalNews(String url,
    {required String sourceName}) async {
  try {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    });
    if (response.statusCode != 200) return [];

    final document = parse(response.body);
    final results = <Map<String, dynamic>>[];

    // 네이버/다음 공통 뉴스 제목 클래스/패턴 대응
    final newsTitles =
        document.querySelectorAll('.news_tit, .tit_main, a[class*="tit"]');

    for (final titleElement in newsTitles) {
      final title = titleElement.text.trim();
      final link = titleElement.attributes['href'] ?? '';

      if (_isCandidacyRelated(title)) {
        final name = _extractNameFromTitle(title);
        if (name != null) {
          results.add(_createCandidateTemplate(name, title, sourceName, link));
        }
      }
    }
    return results;
  } catch (e) {
    print('❌ $sourceName 검색 중 오류: $e');
    return [];
  }
}

bool _isCandidacyRelated(String title) {
  final keywords = [
    '출마',
    '도전',
    '선언',
    '예비후보',
    '지방선거',
    '시장',
    '지사',
    '구청장',
    '차출',
    '물망',
    '공천',
    '경선',
    '전략공천',
    '단일화',
    '대항마',
    '유력',
    '등판',
    '출사표',
    '후보군',
    '인재영입'
  ];
  return keywords.any((k) => title.contains(k)) &&
      !title.contains('불출마') &&
      !title.contains('사퇴') &&
      !title.contains('구속') &&
      !title.contains('재판');
}

String? _extractNameFromTitle(String title) {
  // 간단한 정규식 기반 이름 추출 (2~4글자 한글 뒤에 직함이나 출마 키워드)
  final patterns = [
    RegExp(r'([가-힣]{2,4})\s*(?:전\s*)?(?:총리|의원|지사|시장|구청장|장관|대표|교수)'),
    RegExp(r'([가-힣]{2,4})(?:\s|의)?\s*(?:출마|도전|선언|예비후보)'),
  ];

  for (final p in patterns) {
    final match = p.firstMatch(title);
    if (match != null) {
      final name = match.group(1)!;
      // 노이즈 필터링
      if (!['지방', '선거', '국회', '정치', '출마'].contains(name)) {
        return name;
      }
    }
  }
  return null;
}

Map<String, dynamic> _createCandidateTemplate(
    String name, String title, String source, String url) {
  return {
    'id': 'candidate_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
    'name': name,
    'party': _extractParty(title),
    'district': _extractDistrict(title),
    'imageUrl': '', // 사용자가 직접 등록하기 전까지 기본 아이콘 유지
    'bio': '포털($source) 검색 기반 자동 생성 정보입니다.',
    'electionDate': '2026-06-03T00:00:00.000',
    'term': 0,
    'achievementsList': [title],
    'actions': [title],
    'policies': [],
    'pressReports': [
      {
        'id': 'press_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'source': source,
        'url': url,
        'publishDate': DateTime.now().toIso8601String(),
        'summary': title,
        'sentiment': 'neutral'
      }
    ],
    'electionPossibility': 50.0,
    'lastAnalysisDate': DateTime.now().toIso8601String(),
    'improvementPoints': ['자동 수집 키워드: $title'],
    'polls': [],
    'socialContributions': [],
  };
}

String _extractParty(String title) {
  if (title.contains('국민의힘')) return '국민의힘';
  if (title.contains('더불어민주당') || title.contains('민주당')) return '더불어민주당';
  if (title.contains('조국혁신당')) return '조국혁신당';
  if (title.contains('개혁신당')) return '개혁신당';
  if (title.contains('진보당')) return '진보당';
  return '무소속';
}

String _extractDistrict(String title) {
  if (title.contains('서울')) return '서울특별시장';
  if (title.contains('경기')) return '경기도지사';
  if (title.contains('부산')) return '부산광역시장';
  return '미정';
}

void _mergeCandidateData(
    Map<String, dynamic> existing, Map<String, dynamic> newData) {
  // 보도자료 추가
  final List reports = existing['pressReports'];
  final String newTitle = newData['pressReports'][0]['title'];
  if (!reports.any((r) => r['title'] == newTitle)) {
    reports.insert(0, newData['pressReports'][0]);
  }
  // 정당 정보가 무소속일 경우 업데이트 시도
  if (existing['party'] == '무소속' && newData['party'] != '무소속') {
    existing['party'] = newData['party'];
  }
}

Future<void> _saveCandidatesToFile(
    List<Map<String, dynamic>> candidates) async {
  final file = File('data/election_candidates.json');
  // 기존 파일 읽기
  List<dynamic> existingCandidates = [];
  if (await file.exists()) {
    try {
      existingCandidates = json.decode(await file.readAsString());
    } catch (_) {}
  }

  // 병합 로직 (간소화)
  final Map<String, dynamic> pool = {
    for (var c in existingCandidates) c['name']: c
  };
  for (var c in candidates) {
    final name = c['name'];
    if (pool.containsKey(name)) {
      _mergeCandidateData(pool[name], c);
    } else {
      pool[name] = c;
    }
  }

  await file.writeAsString(
      JsonEncoder.withIndent('  ').convert(pool.values.toList()));
  print('✅ 업데이트 완료. 현재 총 후보 수: ${pool.length}');
}

Future<String> fetchProfileImageUrl(String name) async {
  try {
    final query = Uri.encodeComponent(name);
    final url =
        'https://search.naver.com/search.naver?where=nexearch&query=$query';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    });
    if (response.statusCode == 200) {
      final document = parse(response.body);
      final img = document.querySelector(
          '.profile_wrap img, .detail_info img, .wrap_thumb img, .thumb img');
      if (img != null) {
        final src = img.attributes['src'];
        if (src != null && src.startsWith('http')) {
          return src;
        }
      }
    }
  } catch (e) {
    print('이미지 검색 실패 ($name): $e');
  }
  return 'https://via.placeholder.com/150';
}
