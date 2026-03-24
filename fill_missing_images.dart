import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

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

void main() async {
  final file = File('data/election_candidates.json');
  if (!await file.exists()) {
    print('File not found');
    return;
  }

  final content = await file.readAsString();
  List<dynamic> candidates = json.decode(content);
  int updated = 0;

  for (var c in candidates) {
    final imgUrl = c['imageUrl'] as String?;
    if (imgUrl == null || imgUrl.isEmpty || imgUrl.contains('placeholder.com')) {
      print('Missing image for: ${c['name']}');
      final newUrl = await fetchProfileImageUrl(c['name']);
      if (!newUrl.contains('placeholder.com')) {
        c['imageUrl'] = newUrl;
        updated++;
        print('Found image: $newUrl');
      }
    }
  }

  if (updated > 0) {
    await file.writeAsString(json.encode(candidates));
    print('Updated $updated candidates with profile images.');
  } else {
    print('All candidates already have proper images.');
  }
}
