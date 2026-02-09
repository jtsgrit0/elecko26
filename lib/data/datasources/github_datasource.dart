import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/domain/entities/election_data_export.dart';

/// GitHub API를 통해 선거 데이터를 저장하는 데이터소스
class GitHubDataSource {
  final String owner;
  final String repo;
  final String token;
  final String branch;

  GitHubDataSource({
    required this.owner,
    required this.repo,
    required this.token,
    this.branch = 'main',
  });

  /// 데이터를 GitHub에 저장
  /// 경로: data/election_data.json
  Future<void> saveElectionData(ElectionDataExport data) async {
    try {
      final jsonData = data.toJson();
      final jsonString = jsonEncode(jsonData);
      
      // base64 인코딩
      final encodedContent = base64Encode(utf8.encode(jsonString));
      
      // GitHub API 호출
      final url = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/contents/data/election_data.json',
      );

      // 먼저 기존 파일이 있는지 확인하여 SHA 가져오기
      String? sha;
      try {
        final getResponse = await http.get(
          url,
          headers: {
            'Authorization': 'token $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        ).timeout(const Duration(seconds: 10));

        if (getResponse.statusCode == 200) {
          final jsonResponse = jsonDecode(getResponse.body);
          sha = jsonResponse['sha'];
        }
      } catch (e) {
        // 파일이 없을 수 있음 (처음 생성하는 경우)
      }

      // 파일 생성 또는 업데이트
      final body = {
        'message': 'Update election data - ${DateTime.now().toIso8601String()}',
        'content': encodedContent,
        'branch': branch,
        if (sha != null) 'sha': sha,
      };

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save to GitHub: ${response.statusCode} - ${response.body}');
      }

      print('✓ Election data saved to GitHub: data/election_data.json');
    } catch (e) {
      throw Exception('Error saving election data to GitHub: $e');
    }
  }

  /// 데이터를 JSON 파일로 로컬 저장 (대체 방법)
  /// 앞으로 build/web으로 출력하여 GitHub Pages에서 서빙
  Future<String> generateJsonString(ElectionDataExport data) async {
    final jsonData = data.toJson();
    return jsonEncode(jsonData);
  }

  /// 데이터를 빌 형식 JSON으로 저장 (보기 좋게)
  Future<String> generatePrettyJsonString(ElectionDataExport data) async {
    final jsonData = data.toJson();
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonData);
  }
}
