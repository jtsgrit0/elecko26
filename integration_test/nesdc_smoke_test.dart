import 'dart:io';

import 'package:elecko26_new/data/datasources/nesdc_poll_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NESDC data source smoke test', (WidgetTester tester) async {
    final dataSource = NesdcPollDataSource();

    final entries = await dataSource.fetchLatest(pages: 1);
    print('[NESDC] list entries: ${entries.length}');
    expect(entries, isNotEmpty, reason: 'Entries should be fetched');

    final entry = entries.first;
    print('[NESDC] first entry: ${entry.pollName} (${entry.sourceUrl})');

    final detail = await dataSource.fetchDetail(entry.sourceUrl);
    expect(detail, isNotNull, reason: 'Detail fetch should succeed');

    // Print the HTML for debugging
    print('--- NESDC HTML START ---');
    print(detail?.detailText);
    print('--- NESDC HTML END ---');

    print('[NESDC] detail surveyDate=${detail?.surveyDate}');
    print('[NESDC] detail sampleSize=${detail?.sampleSize}');
    print('[NESDC] detail marginOfError=${detail?.marginOfError}');
    print('[NESDC] detail resultFileUrl=${detail?.resultFileUrl}');
    print('[NESDC] detail text length=${detail?.detailText?.length ?? 0}');
    print('[NESDC] result text length=${detail?.resultText?.length ?? 0}');

    // surveyDate는 null이 아니어야 합니다.
    expect(detail?.surveyDate, isNotNull,
        reason: 'surveyDate should be parsed');
  });
}
