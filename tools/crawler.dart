import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

/// 네이버 뉴스 검색을 스크래핑하여 2026 지방선거 출마 관련 기사를 추출하고,
/// 이를 가상의 의원 데이터 JSON으로 변환하여 저장하는 스크립트입니다.
void main() async {
  print('🚀 크롤링을 시작합니다: 2026 지방선거 출마 선언 검색');

  final candidates = await crawlCandidates();
  
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

  existingCandidates.addAll(newCandidates);

  await file.writeAsString(json.encode(existingCandidates));
  
  print('✅ 총 ${newCandidates.length}명의 새로운 후보가 업데이트 되었습니다.');
  print('전체 등록된 후보 수: ${existingCandidates.length}');
}

Future<List<Map<String, dynamic>>> crawlCandidates() async {
  final query = Uri.encodeComponent('2026 지방선거 출마');
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
    // 출마 의심 기사 판별 규칙
    if (title.contains('출마') || title.contains('도전') || title.contains('선언')) {
      // 제목에서 가장 앞에 나오는 3~4글자의 한글 단어를 임시 이름으로 추출 (실제론 NLP 형태소분석기 필요)
      final nameMatch = RegExp(r'^([가-힣]{2,4})\s').firstMatch(title);
      final name = nameMatch != null ? nameMatch.group(1) : '미상후보_$i';

      if (name != null && name.length <= 4 && !name.contains('출마') && name != '미상후보_$i') {
         // 키워드 추출 (특수문자 제거 후 2글자 이상 단어 최대 5개)
         final keywords = title
             .replaceAll(RegExp(r'[^\w\s가-힣]'), '')
             .split(' ')
             .where((w) => w.length >= 2 && !w.contains(name))
             .take(5)
             .toList();
             
         extracted.add({
          'id': 'candidate_${DateTime.now().millisecondsSinceEpoch}_$i',
          'name': name.replaceAll(RegExp(r'[^가-힣]'), ''),
          'party': title.contains('국민의힘') ? '국민의힘' : (title.contains('민주당') ? '더불어민주당' : '무소속'),
          'district': title.contains('서울') ? '서울특별시' : (title.contains('경기') ? '경기도' : '미정'),
          'imageUrl': 'https://via.placeholder.com/150', // 플레이스홀더
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
              'url': newsTitles[i].attributes['href'] ?? '',
              'publishDate': DateTime.now().toIso8601String(),
              'summary': '주요 기사 키워드: ${keywords.join(', ')}',
              'sentiment': 'neutral'
            }
          ],
          'electionPossibility': 30,
          'lastAnalysisDate': DateTime.now().toIso8601String(),
          'improvementPoints': ['기반 추출 키워드: ${keywords.join(', ')}', '아직 구체적인 정책 공약이 부족합니다.'],
        });
      }
    }
  }

  return extracted;
}
