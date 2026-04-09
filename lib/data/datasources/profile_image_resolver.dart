import 'dart:convert';

import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  /// 너무 자주 검색하지 않도록 기본 TTL을 둡니다.
  static const Duration positiveTtl = Duration(days: 180);
  static const Duration negativeTtl = Duration(days: 14);

  String? getCachedUrl(String memberId) {
    final key = '$_cachePrefix$memberId';
    final value = _local.getString(key);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> cacheUrl(String memberId, String url) async {
    await _local.setString('$_cachePrefix$memberId', url);
    await _local.setString(
        '$_tsPrefix$memberId', DateTime.now().toIso8601String());
    // negative cache clear
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

  /// 주어진 이름으로 가능한 한 “안전한” 프로필 이미지를 찾아 반환합니다.
  /// - Web에서도 동작하도록 MediaWiki API에 `origin=*`를 포함합니다.
  /// - 썸네일(thumb)만 사용합니다.
  Future<String?> resolveImageUrlByName(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) return null;

    // 1) title 직접 조회
    final direct = await _fetchThumbByTitle(name);
    if (direct != null) return direct;

    // 2) 검색 후 첫 결과의 title로 조회
    final title = await _searchTopTitle(name);
    if (title == null) return null;

    return await _fetchThumbByTitle(title);
  }

  Future<String?> _searchTopTitle(String query) async {
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
      final resp = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode != 200) return null;

      final jsonMap =
          json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final queryMap = jsonMap['query'] as Map<String, dynamic>?;
      final results = queryMap?['search'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final title = (first['title'] as String?)?.trim();
      if (title == null || title.isEmpty) return null;
      return title;
    } catch (e) {
      debugPrint('[ProfileImageResolver] search failed: $e');
      return null;
    }
  }

  Future<String?> _fetchThumbByTitle(String title) async {
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
      final resp = await _client.get(uri).timeout(const Duration(seconds: 4));
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
      debugPrint('[ProfileImageResolver] thumb fetch failed: $e');
      return null;
    }
  }
}
