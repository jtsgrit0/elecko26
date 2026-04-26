/// CLI 스크립트: 선거 데이터를 JSON으로 내보내기
/// 사용: dart run bin/export_election_data.dart
/// 또는: flutter pub get && dart run bin/export_election_data.dart
library;

import 'package:elecko26_new/core/di/cli_injection_container.dart' as di;
import 'package:elecko26_new/domain/usecases/export_election_data_usecase.dart';
import 'package:elecko26_new/data/datasources/github_datasource.dart';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  try {
    print('🚀 Starting election data export (CLI Mode)...');
    print('⏰ ${DateTime.now()}');

    // 의존성 순수 다트 버전으로 초기화
    await di.initCli();

    // 데이터 내보내기
    final exportUseCase = di.sl<ExportElectionDataUseCase>();
    final exportData = await exportUseCase.call();

    // JSON 생성
    final jsonData = exportData.toJson();
    final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);

    // 파일 저장 (로컬)
    final outputDir = Directory('data');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final jsonFile = File('${outputDir.path}/election_data.json');
    await jsonFile.writeAsString(prettyJson);
    print('✓ JSON saved to: ${jsonFile.path}');

    // 메타 정보 출력
    print('\n📊 Export Summary:');
    print('├─ Total Members: ${exportData.metadata.totalMembers}');
    print('├─ Members Analyzed: ${exportData.metadata.membersAnalyzed}');
    print(
        '├─ Average Possibility: ${(exportData.metadata.averageElectionPossibility * 100).toStringAsFixed(1)}%');
    print('├─ Total Polls: ${exportData.metadata.totalPolls}');
    print('├─ Data Sources: ${exportData.metadata.dataSourcesCount}');
    print('└─ File Size: ${(prettyJson.length / 1024).toStringAsFixed(2)} KB');

    // 정당별 분석
    print('\n🏛️ Members by Party:');
    exportData.metadata.membersByParty.forEach((party, count) {
      print('├─ $party: $count members');
    });

    // GitHub에 저장 (토큰이 있는 경우)
    final githubDataSource = di.sl<GitHubDataSource>();
    if (githubDataSource.token.isNotEmpty) {
      try {
        await githubDataSource.saveElectionData(exportData);
        print('\n✅ Data exported successfully!');
      } catch (e) {
        print('\n⚠️ GitHub save failed (local file saved): $e');
      }
    } else {
      print('\n⚠️ GitHub token not found. Using local file only.');
      print(
          '   Set GITHUB_TOKEN environment variable to enable GitHub storage.');
    }

    print('\n✓ Export completed at ${DateTime.now()}');
    exit(0);
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print(stackTrace);
    exit(1);
  }
}
