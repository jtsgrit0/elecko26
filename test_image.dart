import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

void main() async {
  final name = '정청래';
  final query = Uri.encodeComponent(name + ' 의원');
  final url = 'https://search.naver.com/search.naver?where=nexearch&query=$query';

  final response = await http.get(Uri.parse(url), headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  });

  if (response.statusCode == 200) {
    final document = parse(response.body);
    // 네이버 인물 정보 프로필 이미지 셀렉터 테스트
    final imgTags = document.querySelectorAll('.profile_wrap img, .detail_info img, .img_thumb img, .thumb img');
    
    for (var img in imgTags) {
      final src = img.attributes['src'];
      if (src != null && src.startsWith('http')) {
        // usually search.pstatic.net
        print('Found: $src');
        return;
      }
    }
    print('Image not found. All img tags:');
    final allImages = document.querySelectorAll('img');
    int count = 0;
    for (var i in allImages) {
        final src = i.attributes['src'];
        if(src != null && src.contains('pstatic.net') && !src.contains('sp_') && !src.contains('gif') && count < 5) {
            print('Fallback: $src');
            count++;
        }
    }
  } else {
    print('Http error');
  }
}
