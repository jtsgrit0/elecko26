import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/domain/entities/historical_election.dart';

/// 역대 선거 데이터를 GitHub Raw 또는 로컬 JSON에서 로드하는 데이터 소스
class HistoricalElectionDataSource {
  static const _baseUrl =
      'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data';

  List<HistoricalElection>? _cachedElections;

  /// 8회 지방선거 요약 데이터를 로드
  Future<List<HistoricalElection>> loadAll() async {
    if (_cachedElections != null) return _cachedElections!;

    final elections = <HistoricalElection>[];

    // 8회 지방선거
    try {
      final data8 = await _fetchJson('historical_election_8th_summary.json');
      if (data8 != null) {
        elections.add(HistoricalElection.fromJson(data8));
      }
    } catch (_) {}

    _cachedElections = elections;
    return elections;
  }

  Future<Map<String, dynamic>?> _fetchJson(String filename) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$filename'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void clearCache() {
    _cachedElections = null;
  }
}
