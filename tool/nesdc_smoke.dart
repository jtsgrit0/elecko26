import 'package:flutter_application_1/data/datasources/nesdc_poll_data_source.dart';

Future<void> main(List<String> args) async {
  final dataSource = NesdcPollDataSource();

  final entries = await dataSource.fetchLatest(pages: 1);
  print('[NESDC] list entries: ${entries.length}');
  if (entries.isEmpty) {
    print('[NESDC] no entries fetched');
    return;
  }

  final entry = entries.first;
  print('[NESDC] first entry: ${entry.pollName} (${entry.sourceUrl})');

  final detail = await dataSource.fetchDetail(entry.sourceUrl);
  if (detail == null) {
    print('[NESDC] detail fetch failed');
    return;
  }

  print('[NESDC] detail surveyDate=${detail.surveyDate}');
  print('[NESDC] detail sampleSize=${detail.sampleSize}');
  print('[NESDC] detail marginOfError=${detail.marginOfError}');
  print('[NESDC] detail resultFileUrl=${detail.resultFileUrl}');
  print('[NESDC] detail text length=${detail.detailText?.length ?? 0}');
  print('[NESDC] result text length=${detail.resultText?.length ?? 0}');

  if (args.isNotEmpty) {
    final name = args.join(' ');
    final rate = detail.findSupportRate([name]);
    print('[NESDC] extracted support rate for "$name": ${rate ?? 'n/a'}');
  }
}
