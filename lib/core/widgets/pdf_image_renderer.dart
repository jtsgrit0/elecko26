import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:pdfrx/pdfrx.dart'; // Changed from pdf_render
import 'dart:ui';
import 'package:image/image.dart' as img; // Added for image encoding

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
    // if (widget.pdfPath.isNotEmpty) {
    //   _imageFuture = _renderPdfPage();
    // }
    _imageFuture = Future.value(null); // PDF 렌더링이 지원되지 않음을 나타냄
  }

  @override
  void didUpdateWidget(PdfImageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (widget.pdfPath != oldWidget.pdfPath ||
    //     widget.pageNumber != oldWidget.pageNumber) {
    //   setState(() {
    //     if (widget.pdfPath.isNotEmpty) {
    //       _imageFuture = _renderPdfPage();
    //     } else {
    //       _imageFuture = null;
    //     }
    //   });
    // }
    // pdfrx가 제거되었으므로 PDF 렌더링은 지원되지 않습니다.
    // 항상 null 또는 null로 해결되는 Future를 설정합니다.
    if (widget.pdfPath.isNotEmpty) {
      _imageFuture = Future.value(null);
    } else {
      _imageFuture = null;
    }
  }

  /*
  Future<Uint8List?> _renderPdfPage() async {
    if (widget.pdfPath.isEmpty) return null;

    PdfDocument? doc;
    try {
      if (widget.pdfPath.startsWith('assets/')) {
        doc = await PdfDocument.openAsset(widget.pdfPath);
      } else {
        doc = await PdfDocument.openFile(widget.pdfPath);
      }

      if (widget.pageNumber > doc.pages.length) {
        return null;
      }

      final page =
          doc.pages[widget.pageNumber - 1]; // pdfrx pages are 0-indexed

      // Render the page with a reasonable resolution
      final double renderWidth = widget.width ?? 200;
      final double renderHeight =
          widget.height ?? (page.height * renderWidth / page.width);

      final PdfPageImage? pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
      );

      if (pageImage == null) {
        return null;
      }

      final img.Image? image = pageImage.createImageNF();
      pageImage.dispose(); // Dispose the PdfPageImage after creating img.Image

      if (image == null) {
        return null;
      }

      final Uint8List imgBytes = img.encodePng(image); // Encode to PNG

      return imgBytes;
    } catch (e) {
      debugPrint('Error rendering PDF page with pdfrx: $e');
      return null;
    } finally {
      doc?.close(); // Close the PdfDocument
    }
  }
  */

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
