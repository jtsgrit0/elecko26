import 'dart:convert';

import 'package:elecko26_new/data/datasources/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class ProfileImageResolver {
  ProfileImageResolver({
    required LocalStorageService localStorageService,
    http.Client? client,
  })  : _local = localStorageService,
        _client = client ?? http.Client();

  final LocalStorageService _local;
  final http.Client _client;

  static const _cachePrefix = 'profile_image_url:';
  static const _tsPrefix = 'profile_image_ts:';
  static const _negativePrefix = 'profile_image_neg:';

  /// 캐시 TTL
  static const Duration positiveTtl = Duration(days: 180);
  static const Duration negativeTtl = Duration(days: 14);

  // HTTP 요청 공통 헤더
  static const _commonHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  String? getCachedUrl(String memberId) {
    final key = '$_cachePrefix$memberId';
    final value = _local.getString(key);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> cacheUrl(String memberId, String url) async {
    await _local.setString('$_cachePrefix$memberId', url);
    await _local.setString(
        '$_tsPrefix$memberId', DateTime.now().toIso8601String());
    await _local.setString('$_negativePrefix$memberId', '');
  }

  Future<void> cacheNegative(String memberId) async {
    await _local.setString(
        '$_negativePrefix$memberId', DateTime.now().toIso8601String());
  }

  bool shouldAttempt(String memberId) {
    final url = getCachedUrl(memberId);
    if (url != null) {
      final ts = _parseTs(_local.getString('$_tsPrefix$memberId'));
      if (ts == null) return true;
      return DateTime.now().difference(ts) > positiveTtl;
    }

    final neg = _parseTs(_local.getString('$_negativePrefix$memberId'));
    if (neg == null) return true;
    return DateTime.now().difference(neg) > negativeTtl;
  }

  DateTime? _parseTs(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return DateTime.tryParse(v.trim());
  }

  /// 다중 소스에서 프로필 이미지 검색 (우선순위: Wikipedia → NamuWiki → Naver → Daum → News)
  Future<String?> resolveImageUrlByName(String displayName,
      {String? party, String? district}) async {
    final name = displayName.trim();
    if (name.isEmpty) return null;

    final searchQuery = _buildSearchQuery(name, party: party, district: district);

    debugPrint('[ProfileImageResolver] Searching for: $searchQuery');

    // 1. Korean Wikipedia
    final wiki = await _resolveWikipedia(name);
    if (wiki != null) {
      debugPrint('[ProfileImageResolver] Found from Wikipedia');
      return wiki;
    }

    // 2. Namu Wiki
    final namu = await _resolveNamuWiki(searchQuery);
    if (namu != null) {
      debugPrint('[ProfileImageResolver] Found from Namu Wiki');
      return namu;
    }

    // 3. Naver Image Search
    final naver = await _resolveNaver(searchQuery);
    if (naver != null) {
      debugPrint('[ProfileImageResolver] Found from Naver');
      return naver;
    }

    // 4. Daum Search
    final daum = await _resolveDaum(searchQuery);
    if (daum != null) {
      debugPrint('[ProfileImageResolver] Found from Daum');
      return daum;
    }

    // 5. Korean News Sites
    final news = await _resolveNewsSites(searchQuery);
    if (news != null) {
      debugPrint('[ProfileImageResolver] Found from News');
      return news;
    }

    debugPrint('[ProfileImageResolver] No image found for: $name');
    return null;
  }

  String _buildSearchQuery(String name, {String? party, String? district}) {
    final parts = [name];
    if (district != null && district.isNotEmpty) parts.add(district);
    if (party != null && party.isNotEmpty) parts.add(party);
    parts.add('국회의원');
    return parts.join(' ');
  }

  // ======================== Wikipedia ========================

  Future<String?> _resolveWikipedia(String name) async {
    // 1) title 직접 조회
    final direct = await _fetchWikipediaThumb(name);
    if (direct != null) return direct;

    // 2) 검색 후 첫 결과
    final title = await _searchWikipedia(name);
    if (title != null) {
      return await _fetchWikipediaThumb(title);
    }
    return null;
  }

  Future<String?> _searchWikipedia(String query) async {
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
      final resp = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;

      final jsonMap =
          json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final queryMap = jsonMap['query'] as Map<String, dynamic>?;
      final results = queryMap?['search'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      return (first['title'] as String?)?.trim();
    } catch (e) {
      debugPrint('[Wikipedia] search failed: $e');
      return null;
    }
  }

  Future<String?> _fetchWikipediaThumb(String title) async {
    try {
      final uri = Uri.https('ko.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'prop': 'pageimages',
        'piprop': 'thumbnail',
        'pithumbsize': '400',
        'titles': title,
        'utf8': '1',
        'origin': '*',
      });
      final resp = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;

      final jsonMap =
          json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final query = jsonMap['query'] as Map<String, dynamic>?;
      final pages = query?['pages'] as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final firstPage = pages.values.first as Map<String, dynamic>;
      final thumb = firstPage['thumbnail'] as Map<String, dynamic>?;
      final source = (thumb?['source'] as String?)?.trim();
      if (source == null || source.isEmpty) return null;
      return source;
    } catch (e) {
      debugPrint('[Wikipedia] thumb fetch failed: $e');
      return null;
    }
  }

  // ======================== Namu Wiki ========================

  Future<String?> _resolveNamuWiki(String query) async {
    try {
      // Namu Wiki 검색
      final searchUri = Uri.parse('https://namu.wiki/api/v2/search').replace(
        queryParameters: {'query': query, 'target': 'name', 'display': '1'},
      );
      final searchResp = await _client
          .get(searchUri, headers: _commonHeaders)
          .timeout(const Duration(seconds: 5));
      if (searchResp.statusCode != 200) return null;

      final results = json.decode(searchResp.body) as List<dynamic>;
      if (results.isEmpty) return null;

      final firstResult = results.first as Map<String, dynamic>;
      final pageTitle = (firstResult['name'] as String?)?.trim();
      if (pageTitle == null) return null;

      // 페이지에서 og:image 추출
      final pageUri = Uri.parse('https://namu.wiki/w/$pageTitle');
      final pageResp = await _client
          .get(pageUri, headers: _commonHeaders)
          .timeout(const Duration(seconds: 5));
      if (pageResp.statusCode != 200) return null;

      final doc = parse(pageResp.body);
      final ogImage = doc.querySelector('meta[property="og:image"]');
      final imageUrl = ogImage?.attributes['content'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }

      // 파일 링크 대체 추출
      final fileLink = doc.querySelector('.wiki-content img');
      return fileLink?.attributes['src'];
    } catch (e) {
      debugPrint('[NamuWiki] failed: $e');
      return null;
    }
  }

  // ======================== Naver ========================

  Future<String?> _resolveNaver(String query) async {
    try {
      final uri = Uri.parse('https://search.naver.com/search.naver').replace(
        queryParameters: {
          'where': 'news',
          'query': '$query 프로필 사진',
          'sm': 'tab_nmr',
        },
      );
      final resp = await _client
          .get(uri, headers: _commonHeaders)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;

      final doc = parse(resp.body);

      // og:image 시도
      final ogImage = doc.querySelector('meta[property="og:image"]');
      final ogUrl = ogImage?.attributes['content'];
      if (ogUrl != null && ogUrl.isNotEmpty && _isValidImageUrl(ogUrl)) {
        return ogUrl;
      }

      // 뉴스 썸네일
      final thumbs = doc.querySelectorAll('.thumb img, ._sp_thumbnail img');
      for (final img in thumbs) {
        final src = img.attributes['src'] ?? img.attributes['data-source'];
        if (src != null && src.isNotEmpty && _isValidImageUrl(src)) {
          return src;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[Naver] failed: $e');
      return null;
    }
  }

  // ======================== Daum ========================

  Future<String?> _resolveDaum(String query) async {
    try {
      final uri = Uri.parse('https://search.daum.net/search').replace(
        queryParameters: {
          'q': query,
          'nil_search': 'art',
        },
      );
      final resp = await _client
          .get(uri, headers: _commonHeaders)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;

      final doc = parse(resp.body);

      // og:image 시도
      final ogImage = doc.querySelector('meta[property="og:image"]');
      final ogUrl = ogImage?.attributes['content'];
      if (ogUrl != null && ogUrl.isNotEmpty && _isValidImageUrl(ogUrl)) {
        return ogUrl;
      }

      // 썸네일 이미지
      final thumbs = doc.querySelectorAll('.thumb_img img, .img_thumb img');
      for (final img in thumbs) {
        final src = img.attributes['src'] ?? img.attributes['data-source'];
        if (src != null && src.isNotEmpty && _isValidImageUrl(src)) {
          return src;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[Daum] failed: $e');
      return null;
    }
  }

  // ======================== Korean News Sites ========================

  Future<String?> _resolveNewsSites(String query) async {
    // 주요 언론사 목록
    final newsSites = [
      {'name': 'chosun', 'url': 'https://search.chosun.com/search/news.html?keyword=$query'},
      {'name': 'joongang', 'url': 'https://search.joongang.co.kr/search?keyword=$query'},
      {'name': 'donga', 'url': 'https://www.donga.com/search?query=$query'},
      {'name': 'hani', 'url': 'https://www.hani.co.kr/search/?q=$query'},
      {'name': 'yna', 'url': 'https://www.yna.co.kr/search?query=$query'},
    ];

    for (final site in newsSites) {
      try {
        final resp = await _client
            .get(Uri.parse(site['url'] as String), headers: _commonHeaders)
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode != 200) continue;

        final doc = parse(resp.body);

        // og:image
        final ogImage = doc.querySelector('meta[property="og:image"]');
        final ogUrl = ogImage?.attributes['content'];
        if (ogUrl != null && ogUrl.isNotEmpty && _isValidImageUrl(ogUrl)) {
          return ogUrl;
        }

        // 썸네일
        final thumbs = doc.querySelectorAll(
            '.photo img, .thumb img, .news_photo img, .media_img img');
        for (final img in thumbs) {
          final src = img.attributes['src'] ?? img.attributes['data-src'];
          if (src != null && src.isNotEmpty && _isValidImageUrl(src)) {
            return src;
          }
        }
      } catch (e) {
        debugPrint('[News:${site['name']}] failed: $e');
      }
    }
    return null;
  }

  // ======================== Helpers ========================

  bool _isValidImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('photo') ||
        lower.contains('image') ||
        lower.contains('thumb') ||
        lower.contains('profile');
  }
}
