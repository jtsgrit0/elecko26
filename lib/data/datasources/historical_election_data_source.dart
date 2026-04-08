import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elecko26/domain/entities/historical_election.dart';

/// 역대 선거 데이터를 GitHub Raw 또는 로컬 JSON에서 로드하는 데이터 소스
class HistoricalElectionDataSource {
  static const _baseUrl =
      'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data';

  List<HistoricalElection>? _cachedElections;

  /// 역대 선거 데이터를 모두 로드 (5회~8회)
  Future<List<HistoricalElection>> loadAll() async {
    if (_cachedElections != null) return _cachedElections!;

    final elections = <HistoricalElection>[];
    final files = [
      'historical_election_5th_summary.json',
      'historical_election_6th_summary.json',
      'historical_election_7th_summary.json',
      'historical_election_8th_summary.json',
    ];

    for (final filename in files) {
      try {
        final data = await _fetchJson(filename);
        if (data != null) {
          elections.add(HistoricalElection.fromJson(data));
        }
      } catch (e) {
        // Log error or skip
      }
    }

    _cachedElections = elections;
    return elections;
  }

  /// PDF에서 추출된 추가 지표(투표율, 관심도 등) 데이터를 로드
  Future<Map<String, dynamic>> loadPdfData() async {
    try {
      final data = await _fetchJson('historical_pdf_data.json');
      return data ?? {};
    } catch (_) {
      return {};
    }
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
