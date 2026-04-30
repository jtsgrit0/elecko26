import 'package:elecko26_new/data/datasources/nesdc_poll_data_source.dart';

Future<void> main(List<String> args) async {
  final dataSource = NesdcPollDataSource();

  final entries = await dataSource.fetchLatest();
  if (entries.isEmpty) {
    return;
  }

  final entry = entries.first;

  final detail = await dataSource.fetchDetail(entry.sourceUrl);
  if (detail == null) {
    return;
  }

  if (args.isNotEmpty) {
    final name = args.join(' ');
    detail.findSupportRate([name]);
  }
}
