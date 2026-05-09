import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  final pdfDir = Directory('assets/pdf');
  final pdfFiles = pdfDir
      .listSync()
      .where((item) => item.path.endsWith('.pdf'))
      .map((item) => item.path)
      .toList();

  final outputDir = Directory('data/pdf_texts');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final pdfPath in pdfFiles) {
    final file = File(pdfPath);
    if (!file.existsSync()) {
      continue;
    }

    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.isNotEmpty) {
        final fileName = pdfPath.split('/').last.replaceAll('.pdf', '.txt');
        final outputFile = File('data/pdf_texts/$fileName');
        await outputFile.writeAsString(text);
      }
    } catch (e) {
      //
    }
  }
}
