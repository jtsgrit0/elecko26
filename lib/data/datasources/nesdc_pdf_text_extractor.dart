import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

String? extractPdfText(Uint8List bytes) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    if (text.isEmpty) {
      return null;
    }
    return text;
  } catch (_) {
    return null;
  }
}
