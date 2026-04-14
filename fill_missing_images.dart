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

Future<String?> fetchWikipediaThumb(String name) async {
  try {
    final uri = Uri.https('ko.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'prop': 'pageimages',
      'piprop': 'thumbnail',
      'pithumbsize': '400',
      'titles': name,
      'utf8': '1',
      'origin': '*',
    });
    final resp = await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return null;

    final jsonMap = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final query = jsonMap['query'] as Map<String, dynamic>?;
    final pages = query?['pages'] as Map<String, dynamic>?;
    if (pages == null || pages.isEmpty) return null;

    final firstPage = pages.values.first as Map<String, dynamic>;
    final thumb = firstPage['thumbnail'] as Map<String, dynamic>?;
    return (thumb?['source'] as String?)?.trim();
  } catch (_) {
    return null;
  }
}

Future<String?> searchWikipedia(String query) async {
  try {
    final uri = Uri.https('ko.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'list': 'search',
      'srsearch': query,
      'srlimit': '1',
      'utf8': '1',
      'origin': '*',
    });
    final resp = await http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return null;

    final jsonMap = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final results = (jsonMap['query'] as Map<String, dynamic>?)?['search'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    return (results.first['title'] as String?)?.trim();
  } catch (_) {
    return null;
  }
}

Future<String?> fetchNamuWikiImage(String name, {String? party, String? district}) async {
  try {
    final searchQuery = [name, district, party].where((e) => e != null && e.isNotEmpty).join(' ');
    final searchUri = Uri.parse('https://namu.wiki/api/v2/search').replace(
      queryParameters: {'query': searchQuery, 'target': 'name', 'display': '1'},
    );
    final searchResp = await http.get(searchUri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 5));
    if (searchResp.statusCode != 200) return null;

    final results = json.decode(searchResp.body) as List<dynamic>;
    if (results.isEmpty) return null;

    final pageTitle = (results.first['name'] as String?)?.trim();
    if (pageTitle == null) return null;

    final pageUri = Uri.parse('https://namu.wiki/w/$pageTitle');
    final pageResp = await http.get(pageUri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 5));
    if (pageResp.statusCode != 200) return null;

    final doc = parse(pageResp.body);
    final ogImage = doc.querySelector('meta[property="og:image"]');
    return ogImage?.attributes['content'];
  } catch (_) {
    return null;
  }
}

Future<String?> fetchNaverImage(String name, {String? party, String? district}) async {
  try {
    final searchQuery = '$name 국회의원';
    final uri = Uri.parse('https://search.naver.com/search.naver').replace(
      queryParameters: {'where': 'news', 'query': searchQuery, 'sm': 'tab_nmr'},
    );
    final resp = await http.get(uri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final doc = parse(resp.body);
    final ogImage = doc.querySelector('meta[property="og:image"]');
    final ogUrl = ogImage?.attributes['content'];
    if (ogUrl != null && ogUrl.isNotEmpty && _isValidImageUrl(ogUrl)) {
      return ogUrl;
    }

    final thumbs = doc.querySelectorAll('.thumb img');
    for (final img in thumbs) {
      final src = img.attributes['src'] ?? img.attributes['data-source'];
      if (src != null && src.isNotEmpty && _isValidImageUrl(src)) {
        return src;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<String?> fetchDaumImage(String name, {String? party, String? district}) async {
  try {
    final searchQuery = '$name 국회의원';
    final uri = Uri.parse('https://search.daum.net/search').replace(
      queryParameters: {'q': searchQuery, 'nil_search': 'art'},
    );
    final resp = await http.get(uri, headers: _commonHeaders)
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;

    final doc = parse(resp.body);
    final ogImage = doc.querySelector('meta[property="og:image"]');
    final ogUrl = ogImage?.attributes['content'];
    if (ogUrl != null && ogUrl.isNotEmpty && _isValidImageUrl(ogUrl)) {
      return ogUrl;
    }

    final thumbs = doc.querySelectorAll('.thumb_img img');
    for (final img in thumbs) {
      final src = img.attributes['src'] ?? img.attributes['data-source'];
      if (src != null && src.isNotEmpty && _isValidImageUrl(src)) {
        return src;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

bool _isValidImageUrl(String url) {
  final lower = url.toLowerCase();
  return (lower.contains('.jpg') || lower.contains('.jpeg') ||
          lower.contains('.png') || lower.contains('.webp') ||
          lower.contains('photo') || lower.contains('image') ||
          lower.contains('thumb') || lower.contains('profile')) &&
      !lower.contains('.gif') && !lower.contains('icon') &&
      !lower.contains('logo') && !lower.contains('blank');
}

Future<String?> resolveImage(String name, {String? party, String? district}) async {
  // 1. Wikipedia
  var img = await fetchWikipediaThumb(name);
  if (img != null) return img;

  final title = await searchWikipedia(name);
  if (title != null) {
    img = await fetchWikipediaThumb(title);
    if (img != null) return img;
  }

  // 2. Namu Wiki
  img = await fetchNamuWikiImage(name, party: party, district: district);
  if (img != null) return img;

  // 3. Naver
  img = await fetchNaverImage(name, party: party, district: district);
  if (img != null) return img;

  // 4. Daum
  img = await fetchDaumImage(name, party: party, district: district);
  if (img != null) return img;

  return null;
}

void main() async {
  final file = File('data/election_candidates.json');
  if (!await file.exists()) {
    print('File not found');
    return;
  }

  final content = await file.readAsString();
  List<dynamic> candidates = json.decode(content);

  final missing = <Map<String, dynamic>>[];
  for (var c in candidates) {
    final imgUrl = c['imageUrl'] as String?;
    if (imgUrl == null || imgUrl.trim().isEmpty) {
      missing.add(c as Map<String, dynamic>);
    }
  }

  print('Missing images for ${missing.length} candidates.\n');

  int updated = 0;
  for (var i = 0; i < missing.length; i++) {
    final c = missing[i];
    final name = c['name'] as String;
    final party = c['party'] as String?;
    final district = c['district'] as String?;

    print('[${i + 1}/${missing.length}] Searching for: $name ($district)');

    final imgUrl = await resolveImage(name, party: party, district: district);

    if (imgUrl != null && imgUrl.isNotEmpty) {
      c['imageUrl'] = imgUrl;
      updated++;
      print('  ✓ Found: $imgUrl');
    } else {
      print('  ✗ No image found');
    }

    // Rate limiting
    await Future.delayed(const Duration(seconds: 2));
  }

  // Write back
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(candidates));

  print('\nDone! Updated $updated/${missing.length} candidates.');
  print('File saved: ${file.path}');
}
