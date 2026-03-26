import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

/// 네이버 뉴스 검색을 스크래핑하여 2026 지방선거 출마 관련 기사를 추출하고,
/// 이를 가상의 의원 데이터 JSON으로 변환하여 저장하는 스크립트입니다.
void main() async {
  print('🚀 크롤링을 시작합니다: 2026 지방선거 출마 선언 검색');

  // 다양한 소스 및 키워드로 검색 확장
  final List<String> searchQueries = [
    '2026 지방선거 출마 선언',
    '2026 지방선거 도전',
    '서울시장 출마 선언',
    '경기도지사 출마 선언',
    '부산시장 출마 선언',
    '대구시장 출마 선언',
    '인천시장 출마 선언',
    '제주도지사 출마 선언',
    '지방선거 예비후보 등록',
  ];

  List<Map<String, dynamic>> allCandidates = [];

  for (final query in searchQueries) {
    print('🔍 크롤링 중: $query');
    final candidates = await crawlCandidates(query);
    allCandidates.addAll(candidates);
    // 서버 과부하 방지 약간의 딜레이
    await Future.delayed(Duration(milliseconds: 500));
  }

  // 전체 수집된 후보 중 중복 제거 (이름 기준)
  final uniqueCandidatesMap = <String, Map<String, dynamic>>{};
  for (final c in allCandidates) {
    uniqueCandidatesMap[c['name']] = c;
  }
  final candidates = uniqueCandidatesMap.values.toList();
  
  if (candidates.isEmpty) {
    print('⚠️ 새로 발견된 후보가 없습니다.');
  }

  // 앱이 읽을 수 있는 형태로 JSON 저장 (data/election_candidates.json)
  final dataDir = Directory('data');
  if (!await dataDir.exists()) {
    await dataDir.create();
  }

  // 기존 파일 읽기
  final file = File('data/election_candidates.json');
  List<dynamic> existingCandidates = [];
  if (await file.exists()) {
    try {
      final content = await file.readAsString();
      existingCandidates = json.decode(content);
    // ignore: empty_catches
    } catch (e) {}
  }

  // 기존 후보 업데이트 및 신규 추가
  final Map<String, dynamic> candidatePool = {
    for (var c in existingCandidates) c['name']: c
  };

  int newCount = 0;
  for (var c in candidates) {
    if (!candidatePool.containsKey(c['name'])) {
      candidatePool[c['name']] = c;
      newCount++;
    } else {
      // 기존 후보 정보 업데이트 (이미지나 최신 기사 등)
      final existing = candidatePool[c['name']]!;
      if (existing['imageUrl'] == null || existing['imageUrl'].toString().contains('placeholder')) {
        existing['imageUrl'] = c['imageUrl'];
      }
      // 최신 보도자료 추가 (중복 체크 생략/간소화)
      if (existing['pressReports'] != null && c['pressReports'] != null) {
        final List reports = existing['pressReports'];
        final String newTitle = c['pressReports'][0]['title'];
        if (!reports.any((r) => r['title'] == newTitle)) {
          reports.insert(0, c['pressReports'][0]);
          if (reports.length > 5) reports.removeLast();
        }
      }
      existing['lastAnalysisDate'] = DateTime.now().toIso8601String();
    }
  }

  // 하차/탈락자 크롤링 및 명단 제거 로직
  print('🔍 하차/탈락 의심 후보를 검색합니다...');
  final dropouts = await crawlDropouts();
  if (dropouts.isNotEmpty) {
    final originalLength = candidatePool.length;
    candidatePool.removeWhere((name, _) => dropouts.contains(name));
    final removedCount = originalLength - candidatePool.length;
    if (removedCount > 0) {
      print('🗑️ 하차/탈락 키워드로 인해 $removedCount 명의 후보가 명단에서 제거되었습니다.');
    }
  }

  await file.writeAsString(JsonEncoder.withIndent('  ').convert(candidatePool.values.toList()));
  
  print('✅ 총 $newCount 명의 새로운 후보가 추가되었습니다.');
  print('전체 등록된 후보 수: ${candidatePool.length}');
}

Future<Set<String>> crawlDropouts() async {
  final query = Uri.encodeComponent('2026 지방선거 "불출마" OR "사퇴" OR "탈락"');
  final url = 'https://search.naver.com/search.naver?where=news&query=$query';

  final response = await http.get(Uri.parse(url), headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  });

  if (response.statusCode != 200) return {};

  final document = parse(response.body);
  final newsTitles = document.querySelectorAll('.news_tit');
  final Set<String> dropoutNames = {};

  for (int i = 0; i < newsTitles.length; i++) {
    final title = newsTitles[i].text.trim();
    if (title.contains('불출마') || title.contains('사퇴') || title.contains('탈락') || title.contains('포기')) {
      // 이름 추출 최적화: "홍길동 불출마" 또는 "홍길동, 지방선거 사퇴" 등
      final nameMatch = RegExp(r'([가-힣]{2,4})(?:\s|[,])(?:불출마|사퇴|탈락|포기|의원|시장|지사)').firstMatch(title);
      if (nameMatch != null) {
        dropoutNames.add(nameMatch.group(1)!);
      }
    }
  }
  return dropoutNames;
}

Future<List<Map<String, dynamic>>> crawlCandidates(String searchKeyword) async {
  final query = Uri.encodeComponent(searchKeyword);
  final url = 'https://search.naver.com/search.naver?where=news&query=$query';

  final response = await http.get(Uri.parse(url), headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  });

  if (response.statusCode != 200) {
    print('❌ 네이버 뉴스 검색에 실패했습니다. (상태 코드: ${response.statusCode})');
    return [];
  }

  final document = parse(response.body);
  final newsTitles = document.querySelectorAll('.news_tit');
  
  // 실제 서비스라면 LLM API(OpenAI/Gemini)에 본문을 통째로 넘겨 인물 정보를 추출하는 것이 정확합니다.
  // 이 예제에서는 데모를 위해 고유명사나 특정 키워드를 기반으로 간단한 모의 추출을 수행합니다.

  List<Map<String, dynamic>> extracted = [];

  for (int i = 0; i < newsTitles.length; i++) {
    final title = newsTitles[i].text.trim();
    final url = newsTitles[i].attributes['href'] ?? '';
    
    // 출마 의심 기사 판별 규칙 강화
    if (title.contains('출마') || title.contains('도전') || title.contains('선언') || title.contains('예비후보') || title.contains('도전장')) {
      
      // 고도화된 이름 추출 로직
      // 1. "직함" 앞의 단어를 이름으로 추정 (예: 김부겸 전 총리 -> 김부겸)
      // 2. "이름+출마" (예: 홍길동 출마 -> 홍길동)
      final rankPattern = RegExp(r'([가-힣]{2,4})\s*(?:전\s*)?(?:총리|의원|지사|시장|구청장|장관|대표|부의장|부장|교수)');
      final declarePattern = RegExp(r'([가-힣]{2,4})(?:\s|[,]|의)?\s*(?:출마|도전|선언|예비후보|등록)');
      
      String? name;
      final rankMatch = rankPattern.firstMatch(title);
      if (rankMatch != null) {
        name = rankMatch.group(1);
      } else {
        final declareMatch = declarePattern.firstMatch(title);
        if (declareMatch != null) {
          name = declareMatch.group(1);
        }
      }

      // 예외 이름 필터링 (조사 등이 섞인 경우 방지)
      if (name != null) {
        name = name.replaceAll(RegExp(r'[가-힣]+(이|가|은|는|의|를|을)$'), '');
        if (name.length < 2 || name.length > 4 || ['지방', '선거', '국회', '정치', '민심', '출마', '도전'].contains(name)) {
          name = null;
        }
      }

      if (name != null) {
         final words = title.split(' ');
         final keywords = words
             .map((w) => w.replaceAll(RegExp(r'[^\w\s가-힣]'), ''))
             .where((w) => w.length >= 2 && w != name)
             .take(5)
             .toList();

         print('📸 [$name] 프로필 이미지 검색 중...');
         final imageUrl = await fetchProfileImageUrl(name);
         
         String party = '무소속';
         if (title.contains('국민의힘') || title.contains('국힘')) party = '국민의힘';
         else if (title.contains('민주당') || title.contains('더불어민주당')) party = '더불어민주당';
         else if (title.contains('조국혁신당')) party = '조국혁신당';
         else if (title.contains('개혁신당')) party = '개혁신당';
         else if (title.contains('정의당')) party = '정의당';
         else if (title.contains('진보당')) party = '진보당';
         else if (title.contains('기본소득당')) party = '기본소득당';

         String district = '전국';
         if (title.contains('서울')) district = '서울특별시장';
         else if (title.contains('경기')) district = '경기도지사';
         else if (title.contains('부산')) district = '부산광역시장';
         else if (title.contains('대구')) district = '대구광역시장';
         else if (title.contains('인천')) district = '인천광역시장';
         else if (title.contains('광주')) district = '광주광역시장';
         else if (title.contains('대전')) district = '대전광역시장';
         else if (title.contains('울산')) district = '울산광역시장';
         else if (title.contains('제주')) district = '제주특별자치도지사';
             
         extracted.add({
          'id': 'candidate_${DateTime.now().millisecondsSinceEpoch}_$i',
          'name': name,
          'party': party,
          'district': district,
          'imageUrl': imageUrl,
          'bio': '포털 뉴스 기반 생성. 주요 키워드: #${keywords.join(' #')}',
          'electionDate': '2026-06-03T00:00:00.000',
          'term': 0,
          'achievementsList': [title],
          'actions': ['최근 행보 키워드: ${keywords.join(', ')}'],
          'policies': [],
          'pressReports': [
            {
              'id': 'press_${DateTime.now().millisecondsSinceEpoch}_$i',
              'title': title,
              'source': '뉴스검색',
              'url': url,
              'publishDate': DateTime.now().toIso8601String(),
              'summary': '주요 기사 키워드: ${keywords.join(', ')}',
              'sentiment': 'neutral'
            }
          ],
          'electionPossibility': 50.0, // UI 호환성을 위해 double 타입 명시 
          'lastAnalysisDate': DateTime.now().toIso8601String(),
          'improvementPoints': ['기반 추출 키워드: ${keywords.join(', ')}'],
        });
      }
    }
  }

  return extracted;
}

Future<String> fetchProfileImageUrl(String name) async {
  try {
    final query = Uri.encodeComponent(name);
    final url = 'https://search.naver.com/search.naver?where=nexearch&query=$query';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    });
    if (response.statusCode == 200) {
      final document = parse(response.body);
      final img = document.querySelector('.profile_wrap img, .detail_info img, .wrap_thumb img, .thumb img');
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
