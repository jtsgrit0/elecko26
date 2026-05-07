import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_render/pdf_render.dart';
import 'dart:ui';

class PdfImageRenderer extends StatefulWidget {
  final String pdfPath;
  final int pageNumber;
  final double? width;
  final double? height;
  final Widget Function(BuildContext)? placeholder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorWidget;

  const PdfImageRenderer({
    Key? key,
    required this.pdfPath,
    required this.pageNumber,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  factory PdfImageRenderer.fromUrl(
    String url, {
    Key? key,
    double? width,
    double? height,
    Widget Function(BuildContext)? placeholder,
    Widget Function(BuildContext, Object, StackTrace?)? errorWidget,
  }) {
    if (url.startsWith('assets/') && url.contains(':')) {
      final parts = url.split(':');
      if (parts.length == 2) {
        final pdfPath = parts[0];
        final pageNumber = int.tryParse(parts[1]) ?? 1;
        return PdfImageRenderer(
          key: key,
          pdfPath: pdfPath,
          pageNumber: pageNumber,
          width: width,
          height: height,
          placeholder: placeholder,
          errorWidget: errorWidget,
        );
      }
    }
    // Return error widget if URL is not in the expected format
    return PdfImageRenderer(
      key: key,
      pdfPath: '', // Invalid path
      pageNumber: 1,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  @override
  _PdfImageRendererState createState() => _PdfImageRendererState();
}

class _PdfImageRendererState extends State<PdfImageRenderer> {
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.pdfPath.isNotEmpty) {
      _imageFuture = _renderPdfPage();
    }
  }

  @override
  void didUpdateWidget(PdfImageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pdfPath != oldWidget.pdfPath ||
        widget.pageNumber != oldWidget.pageNumber) {
      setState(() {
        if (widget.pdfPath.isNotEmpty) {
          _imageFuture = _renderPdfPage();
        } else {
          _imageFuture = null;
        }
      });
    }
  }

  Future<Uint8List?> _renderPdfPage() async {
    if (widget.pdfPath.isEmpty) return null;
    try {
      final doc = await PdfDocument.openFile(widget.pdfPath);
      if (widget.pageNumber > doc.pageCount) {
        await doc.dispose();
        return null;
      }
      final page = await doc.getPage(widget.pageNumber);
      final imgPDF = await page.render(width: 200); // 해상도 조절
      final img = await imgPDF.createImageDetached();
      final imgBytes = await img.toByteData(format: ImageByteFormat.png);
      await doc.dispose();
      return imgBytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error rendering PDF page: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFuture == null) {
      if (widget.errorWidget != null) {
        return widget.errorWidget!(
            context, 'Invalid PDF path', StackTrace.current);
      }
      return SizedBox(width: widget.width, height: widget.height);
    }

    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (widget.placeholder != null) {
            return widget.placeholder!(context);
          }
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          if (widget.errorWidget != null) {
            return widget.errorWidget!(context, snapshot.error ?? 'No data',
                snapshot.stackTrace ?? StackTrace.current);
          }
          return SizedBox(width: widget.width, height: widget.height);
        } else {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
          );
        }
      },
    );
  }
}
