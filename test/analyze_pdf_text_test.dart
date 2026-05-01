import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elecko26_new/domain/usecases/nesdc_pdf_extractor.dart';

void main() {
  test('Analyze extracted PDF text for support rates', () async {
    final textFiles = [
      'data/pdf_texts/MON0120180035_0001S.txt',
      'data/pdf_texts/MON0120070003_0001S.txt',
    ];

    for (final filePath in textFiles) {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      debugPrint('Analyzing $filePath...');
      final text = await file.readAsString();

      final rates = NesdcPdfExtractor.extractSupportRates(text);
      debugPrint('  Found ${rates.length} support rate entries');
      if (rates.isNotEmpty) {
        rates.forEach((name, rate) {
          debugPrint('    $name: ${(rate * 100).toStringAsFixed(1)}%');
        });
      }

      final metadata = NesdcPdfExtractor.extractPollMetadata(text);
      debugPrint('  Metadata: $metadata');

      final partyData = NesdcPdfExtractor.extractByParty(text);
      debugPrint('  Found ${partyData.length} party sections');
    }
  });
}
