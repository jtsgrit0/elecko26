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
    '2026 지방선거 출마',
    '2026 지방선거 도전',
    '2026 지방선거 선언',
    '서울시장 출마',
    '경기도지사 출마',
    '부산시장 출마',
    '인천시장 출마',
  ];

  List<Map<String, dynamic>> allCandidates = [];

  for (final query in searchQueries) {
    print('🔍 크롤링 중: $query');
    final candidates = await crawlCandidates(query);
    allCandidates.addAll(candidates);
    // 서버 과부하 방지 약간의 딜레이
    await Future.delayed(Duration(seconds: 1));
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

  // 간단한 중복 제거 (이름 기준)
  final existingNames = existingCandidates.map((c) => c['name']).toSet();
  final newCandidates = candidates.where((c) => !existingNames.contains(c['name'])).toList();

  // 하차/탈락자 크롤링 및 명단 제거 로직
  print('🔍 하차/탈락 의심 후보를 검색합니다...');
  final dropouts = await crawlDropouts();
  if (dropouts.isNotEmpty) {
    final originalLength = existingCandidates.length;
    existingCandidates.removeWhere((c) => dropouts.contains(c['name']));
    final removedCount = originalLength - existingCandidates.length;
    if (removedCount > 0) {
      print('🗑️ 하차/탈락 키워드로 인해 $removedCount 명의 후보가 명단에서 제거성공되었습니다.');
    }
  }

  await file.writeAsString(json.encode(existingCandidates));
  
  print('✅ 총 ${newCandidates.length}명의 새로운 후보가 업데이트 되었습니다.');
  print('전체 등록된 후보 수: ${existingCandidates.length}');
}

Future<Set<String>> crawlDropouts() async {
  final query = Uri.encodeComponent('2026 지방선거 불출마 OR 사퇴 OR 탈락');
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
      final nameMatch = RegExp(r'^([가-힣]{2,4})\s').firstMatch(title);
      if (nameMatch != null) {
        final name = nameMatch.group(1)!;
        if (name.length <= 4 && !name.contains('출마')) {
          dropoutNames.add(name);
        }
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
  final newsDescriptions = document.querySelectorAll('.dsc_txt_wrap'); // 수정 가능
  
  // 실제 서비스라면 LLM API(OpenAI/Gemini)에 본문을 통째로 넘겨 인물 정보를 추출하는 것이 정확합니다.
  // 이 예제에서는 데모를 위해 고유명사나 특정 키워드를 기반으로 간단한 모의 추출을 수행합니다.

  List<Map<String, dynamic>> extracted = [];

  for (int i = 0; i < newsTitles.length; i++) {
    final title = newsTitles[i].text.trim();
    final url = newsTitles[i].attributes['href'] ?? '';
    
    // 출마 의심 기사 판별 규칙 완화
    if (title.contains('출마') || title.contains('도전') || title.contains('선언') || title.contains('후보')) {
      // 좀 더 유연한 이름 추출: 뉴스 제목의 앞부분을 이름으로 추정
      // 실무에서는 NLP 형태소분석기/NER 모델을 씁니다. 데모를 위해 규칙을 매우 느슨하게 가져갑니다.
      final words = title.split(' ');
      String? name;
      
      for(var w in words) {
        final cleanWord = w.replaceAll(RegExp(r'[^가-힣]'), '');
        // 보통 사람 이름은 한국어 2~4글자
        if(cleanWord.length >= 2 && cleanWord.length <= 4 && !cleanWord.contains('출마') && !cleanWord.contains('선거') && !cleanWord.contains('도전')) {
            name = cleanWord;
            break;
        }
      }

      if (name != null) {
         // 키워드 추출
         final keywords = words
             .map((w) => w.replaceAll(RegExp(r'[^\w\s가-힣]'), ''))
             .where((w) => w.length >= 2 && w != name)
             .take(5)
             .toList();

         print('📸 [$name] 프로필 이미지 검색 중...');
         final imageUrl = await fetchProfileImageUrl(name);
             
         extracted.add({
          'id': 'candidate_${DateTime.now().millisecondsSinceEpoch}_$i',
          'name': name,
          'party': title.contains('국민의힘') ? '국민의힘' : (title.contains('민주당') ? '더불어민주당' : (title.contains('개혁신당') ? '개혁신당' : '무소속')),
          'district': title.contains('서울') ? '서울특별시장' : (title.contains('경기') ? '경기도지사' : (title.contains('부산') ? '부산광역시장' : '전국')),
          'imageUrl': imageUrl,
          'bio': '포털 뉴스 출마 확인. 주요 키워드: #${keywords.join(' #')}',
          'electionDate': '2026-06-03',
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
