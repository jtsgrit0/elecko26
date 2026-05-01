import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

const _commonHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept':
      'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
};

// 유효한 이미지인지 확인 (플레이스홀더, 아이콘, 로고 등 제외)
bool isValidImage(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('ssl.pstatic.net/sstatic/search/common/og'))
    return false; // 네이버 검색 기본 이미지
  if (lower.contains('daum_og.png')) return false; // 다음 검색 기본 이미지
  if (lower.contains('placeholder.com')) return false;
  if (lower.contains('replace_this_image')) return false; // 위키미디어 플레이스홀더
  if (lower.endsWith('.svg')) return false; // 벡터 아이콘 제외
  if (lower.contains('logo') && lower.contains('.png'))
    return false; // 로고 이미지 제외 가능성
  return true;
}

Future<String?> fetchWikipediaThumb(String name,
    {String? party, String? district}) async {
  try {
    // 정치인 동명이인을 위해 "이름 (정치인)" 형식 우선 시도
    final titleQuery = '$name (정치인)';
    final uri = Uri.https('ko.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'prop': 'pageimages',
      'piprop': 'thumbnail',
      'pithumbsize': '400',
      'titles': titleQuery,
      'utf8': '1',
      'origin': '*',
    });
    final resp = await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return null;

    final jsonMap =
        json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final query = jsonMap['query'] as Map<String, dynamic>?;
    final pages = query?['pages'] as Map<String, dynamic>?;

    if (pages != null && pages.isNotEmpty) {
      final firstPage = pages.values.first as Map<String, dynamic>;
      final thumb = firstPage['thumbnail'] as Map<String, dynamic>?;
      final source = (thumb?['source'] as String?)?.trim();
      if (source != null) return source;
    }

    // (정치인) 페이지가 없으면 이름으로 검색
    return await _searchWikipedia(name);
  } catch (_) {
    return null;
  }
}

Future<String?> _searchWikipedia(String query) async {
  try {
    final uri = Uri.https('ko.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'list': 'search',
      'srsearch': query,
      'srlimit': '3',
      'utf8': '1',
      'origin': '*',
    });
    final resp = await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return null;

    final jsonMap =
        json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final results = (jsonMap['query'] as Map<String, dynamic>?)?['search']
        as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    // 첫 번째 결과의 썸네일 가져오기
    final title = (results.first['title'] as String?)?.trim();
    if (title == null) return null;

    final uriThumb = Uri.https('ko.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'prop': 'pageimages',
      'piprop': 'thumbnail',
      'pithumbsize': '400',
      'titles': title,
      'utf8': '1',
      'origin': '*',
    });
    final respThumb =
        await http.get(uriThumb).timeout(const Duration(seconds: 5));
    if (respThumb.statusCode != 200) return null;

    final jsonMapThumb =
        json.decode(utf8.decode(respThumb.bodyBytes)) as Map<String, dynamic>;
    final queryThumb = jsonMapThumb['query'] as Map<String, dynamic>?;
    final pagesThumb = queryThumb?['pages'] as Map<String, dynamic>?;
    if (pagesThumb != null && pagesThumb.isNotEmpty) {
      final firstPage = pagesThumb.values.first as Map<String, dynamic>;
      final thumb = firstPage['thumbnail'] as Map<String, dynamic>?;
      return (thumb?['source'] as String?)?.trim();
    }

    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> fetchNamuWikiImage(String name,
    {String? party, String? district}) async {
  try {
    // 나무위키 검색어 구성: "이름 선거구" 또는 "이름 정당"
    final parts = [name];
    if (district != null && district.isNotEmpty) parts.add(district);
    if (party != null && party.isNotEmpty) parts.add(party);
    final searchQuery = parts.join(' ');

    final searchUri = Uri.parse('https://namu.wiki/api/v2/search').replace(
      queryParameters: {'query': searchQuery, 'target': 'name', 'display': '3'},
    );
    final searchResp = await http
        .get(searchUri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 5));
    if (searchResp.statusCode != 200) return null;

    final results = json.decode(searchResp.body) as List<dynamic>;
    if (results.isEmpty) return null;

    // 검색 결과 중 가장 관련성 높은 페이지의 이미지 추출 시도
    for (final res in results) {
      final pageTitle = (res['name'] as String?)?.trim();
      if (pageTitle == null) continue;

      final pageUri = Uri.parse('https://namu.wiki/w/$pageTitle');
      final pageResp = await http
          .get(pageUri, headers: _commonHeaders)
          .timeout(const Duration(seconds: 5));
      if (pageResp.statusCode != 200) continue;

      final doc = parse(pageResp.body);
      final ogImage = doc.querySelector('meta[property="og:image"]');
      final url = ogImage?.attributes['content'];
      if (url != null && url.isNotEmpty && isValidImage(url)) {
        return url;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> fetchNaverImage(String name,
    {String? party, String? district}) async {
  try {
    // 네이버 뉴스 검색: "이름 선거구 정당"
    final parts = [name];
    if (district != null && district.isNotEmpty) parts.add(district);
    if (party != null && party.isNotEmpty) parts.add(party);
    final searchQuery = parts.join(' ');

    final uri = Uri.parse('https://search.naver.com/search.naver').replace(
      queryParameters: {'where': 'news', 'query': searchQuery, 'sm': 'tab_nmr'},
    );
    final resp = await http
        .get(uri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final doc = parse(resp.body);

    // 1. og:image 시도
    final ogImage = doc.querySelector('meta[property="og:image"]');
    final ogUrl = ogImage?.attributes['content'];
    if (ogUrl != null && ogUrl.isNotEmpty && isValidImage(ogUrl)) {
      return ogUrl;
    }

    // 2. 뉴스 썸네일 이미지
    // 네이버 뉴스 리스트의 썸네일 클래스는 변경될 수 있으나 일반적인 img 태그 탐색
    final thumbs =
        doc.querySelectorAll('.news_wrap img, .thumb img, .photo img');
    for (final img in thumbs) {
      final src = img.attributes['src'] ?? img.attributes['data-source'];
      if (src != null && src.isNotEmpty && isValidImage(src)) {
        return src;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> fetchDaumImage(String name,
    {String? party, String? district}) async {
  try {
    // 다음 뉴스 검색
    final parts = [name];
    if (district != null && district.isNotEmpty) parts.add(district);
    if (party != null && party.isNotEmpty) parts.add(party);
    final searchQuery = parts.join(' ');

    final uri = Uri.parse('https://search.daum.net/search').replace(
      queryParameters: {'q': searchQuery, 'nil_search': 'art'},
    );
    final resp = await http
        .get(uri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final doc = parse(resp.body);

    // og:image
    final ogImage = doc.querySelector('meta[property="og:image"]');
    final ogUrl = ogImage?.attributes['content'];
    if (ogUrl != null && ogUrl.isNotEmpty && isValidImage(ogUrl)) {
      return ogUrl;
    }

    // 썸네일
    final thumbs = doc.querySelectorAll('.thumb_img img, .img_thumb img');
    for (final img in thumbs) {
      final src = img.attributes['src'] ?? img.attributes['data-source'];
      if (src != null && src.isNotEmpty && isValidImage(src)) {
        return src;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> resolveImage(String name,
    {String? party, String? district}) async {
  // 1. Wikipedia (가장 정확도 높음)
  var img = await fetchWikipediaThumb(name, party: party, district: district);
  if (img != null && isValidImage(img)) return img;

  // 2. Namu Wiki
  img = await fetchNamuWikiImage(name, party: party, district: district);
  if (img != null && isValidImage(img)) return img;

  // 3. Naver News
  img = await fetchNaverImage(name, party: party, district: district);
  if (img != null && isValidImage(img)) return img;

  // 4. Daum News
  img = await fetchDaumImage(name, party: party, district: district);
  if (img != null && isValidImage(img)) return img;

  return null;
}

void main() async {
  final file = File('data/election_candidates.json');
  if (!await file.exists()) {
    print('File not found: ${file.path}');
    return;
  }

  final content = await file.readAsString();
  List<dynamic> candidates = json.decode(content);

  int updated = 0;
  int skipped = 0;

  for (int i = 0; i < candidates.length; i++) {
    final c = candidates[i] as Map<String, dynamic>;
    final name = c['name'] as String;
    final party = c['party'] as String?;
    final district = c['district'] as String?;
    String? imgUrl = c['imageUrl'] as String?;

    // 이미 이미지가 있거나, 유효하지 않은 이미지는 다시 탐색
    final needsUpdate =
        (imgUrl == null || imgUrl.trim().isEmpty || !isValidImage(imgUrl));

    if (needsUpdate) {
      print('[$i/${candidates.length}] Searching: $name ($district / $party)');

      // 2초 딜레이 (서버 부하 방지)
      await Future.delayed(const Duration(seconds: 2));

      final newUrl = await resolveImage(name, party: party, district: district);
      if (newUrl != null) {
        c['imageUrl'] = newUrl;
        updated++;
        print('  ✓ Found: $newUrl');
      } else {
        c['imageUrl'] = ''; // 빈 값으로 명시적 초기화
        skipped++;
        print('  ✗ Not found');
      }
    } else {
      // print('[$i] Skip: $name (Already has valid image)');
    }
  }

  // 저장
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(candidates));

  print('\n=== Result ===');
  print('Updated: $updated');
  print('Skipped/Not Found: $skipped');
  print('File saved: ${file.path}');
}
