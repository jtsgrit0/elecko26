/// CLI script: export NESDC poll cache for web (CORS-safe)
/// Usage: dart run bin/export_nesdc_polls.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/core/config/refresh_config.dart';
import 'package:flutter_application_1/data/datasources/nesdc_poll_data_source.dart';

Future<void> main(List<String> args) async {
  final pages = _readInt('NESDC_PAGES', kNesdcPagesToFetch);
  final limit = _readInt('NESDC_LIMIT', 20);

  print('[NESDC] Export start: pages=$pages limit=$limit');

  final dataSource = NesdcPollDataSource();
  final entries = await dataSource.fetchLatest(pages: pages);
  final sliced = entries.length > limit ? entries.take(limit).toList() : entries;

  final outputEntries = <Map<String, dynamic>>[];
  var index = 0;
  for (final entry in sliced) {
    index += 1;
    print('[NESDC] Fetch detail $index/${sliced.length}: ${entry.sourceUrl}');
    final detail = await dataSource.fetchDetail(entry.sourceUrl);
    outputEntries.add({
      'registrationNo': entry.registrationNo,
      'agency': entry.agency,
      'client': entry.client,
      'method': entry.method,
      'sampleFrame': entry.sampleFrame,
      'pollName': entry.pollName,
      'registeredDate': entry.registeredDate.toIso8601String(),
      'region': entry.region,
      'sourceUrl': entry.sourceUrl,
      'status': entry.status,
      'detail': detail == null
          ? null
          : {
              'surveyDate': detail.surveyDate?.toIso8601String(),
              'sampleSize': detail.sampleSize,
              'marginOfError': detail.marginOfError,
              'resultFileUrl': detail.resultFileUrl,
              'detailText': detail.detailText,
              'resultText': detail.resultText,
              'fields': detail.fields,
            },
    });
  }

  final payload = {
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'entries': outputEntries,
  };

  final outputDir = Directory('data');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final compactFile = File('${outputDir.path}/nesdc_polls.json');
  await compactFile.writeAsString(jsonEncode(payload));

  final prettyFile = File('${outputDir.path}/nesdc_polls_pretty.json');
  await prettyFile.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

  print('[NESDC] Exported ${outputEntries.length} entries');
  print('[NESDC] Saved: ${compactFile.path}');
  print('[NESDC] Saved: ${prettyFile.path}');
}

int _readInt(String name, int fallback) {
  final raw = Platform.environment[name];
  if (raw == null || raw.trim().isEmpty) {
    return fallback;
  }
  return int.tryParse(raw.trim()) ?? fallback;
}
