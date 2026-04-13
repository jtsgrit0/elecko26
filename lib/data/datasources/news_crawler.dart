import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:elecko26/domain/entities/member.dart';

/// Naver 뉴스 검색을 통해 후보자 관련 뉴스를 수집하는 데이터소스
class NewsCrawler {
  static const String _naverNewsSearchUrl = 'https://search.naver.com/search.naver';

  /// 후보자 이름으로 Naver 뉴스 검색 후 PressReport 리스트 반환
  Future<List<PressReport>> crawlNewsForCandidate(String candidateName) async {
    final reports = <PressReport>[];

    try {
      final uri = Uri.parse(_naverNewsSearchUrl).replace(queryParameters: {
        'where': 'news',
        'query': candidateName,
        'sm': 'tab_nmr',
      });

      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return reports;

      final document = parse(response.body);

      // Naver 뉴스 검색 결과 파싱
      final newsItems = document.querySelectorAll('.news_wrap');
      for (int i = 0; i < newsItems.length && i < 5; i++) {
        try {
          final item = newsItems[i];

          // 제목
          final titleEl = item.querySelector('.news_tit a') ??
              item.querySelector('.news_tit .link_tit');
          final title = titleEl?.text.trim() ?? '';
          if (title.isEmpty) continue;

          // 링크
          final url = titleEl?.attributes['href'] ?? '';
          if (url.isEmpty || !url.contains('http')) continue;

          // 언론사
          final sourceEl =
              item.querySelector('.press_img a') ?? item.querySelector('.info_group ..press');
          final source = sourceEl?.text.trim() ?? 'Naver';

          // 요약/내용
          final summaryEl = item.querySelector('.api_txt_lines') ??
              item.querySelector('.news_dsc .dsc_txt_wrap');
          final summary = summaryEl?.text.trim() ?? '';

          // 날짜
          final dateEl = item.querySelector('.info_group .date') ??
              item.querySelector('.api_txt_lines .date');
          final dateText = dateEl?.text.trim() ?? '';
          final publishDate = _parseDate(dateText);

          reports.add(PressReport(
            id: 'naver_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: title,
            source: source,
            url: url,
            publishDate: publishDate,
            summary: summary.length > 200 ? '${summary.substring(0, 200)}...' : summary,
            sentiment: 'neutral',
          ));
        } catch (_) {}
      }
    } catch (_) {}

    return reports;
  }

  /// 여러 후보의 뉴스를 병렬로 수집
  Future<Map<String, List<PressReport>>> crawlNewsForCandidates(
      List<String> candidateNames) async {
    final results = <String, List<PressReport>>{};

    final futures = candidateNames.map((name) async {
      final reports = await crawlNewsForCandidate(name);
      results[name] = reports;
    });

    await Future.wait(futures);
    return results;
  }

  /// 날짜 문자열 파싱 (예: "2026.04.13.", "3시간 전", "어제")
  DateTime _parseDate(String dateText) {
    try {
      final cleaned = dateText.replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (cleaned.contains('.')) {
        final parts = cleaned.split('.');
        if (parts.length >= 3) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1].padLeft(2, '0')),
            int.parse(parts[2].padLeft(2, '0')),
          );
        }
      }
    } catch (_) {}

    // 파싱 실패 시 현재 시간 반환
    return DateTime.now();
  }
}
