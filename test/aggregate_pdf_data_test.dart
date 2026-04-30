import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elecko26_new/domain/usecases/nesdc_pdf_extractor.dart';

void main() {
  test('Aggregate all extracted PDF data to JSON', () async {
    final textDir = Directory('data/pdf_texts');
    if (!textDir.existsSync()) return;

    final aggregatedData = <String, Map<String, double>>{};

    final files = textDir.listSync().whereType<File>().toList();
    for (final file in files) {
      if (!file.path.endsWith('.txt')) continue;

      final fileName = file.path.split('/').last;
      debugPrint('Processing $fileName...');
      final text = await file.readAsString();

      final rates = NesdcPdfExtractor.extractSupportRates(text);
      if (rates.isNotEmpty) {
        aggregatedData[fileName] = rates;
        debugPrint('  Added ${rates.length} points');
      }
    }

    final outputFile = File('data/historical_pdf_data.json');
    await outputFile.writeAsString(
        // ignore: prefer_const_constructors
        JsonEncoder.withIndent('  ').convert(aggregatedData));
    debugPrint('Saved to ${outputFile.path}');

    expect(true, true);
  });
}
