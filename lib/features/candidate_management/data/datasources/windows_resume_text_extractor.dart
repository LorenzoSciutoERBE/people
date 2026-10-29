import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:pdfrx/pdfrx.dart';

import '../../domain/repositories/resume_text_extractor.dart';

class WindowsResumeTextExtractor implements ResumeTextExtractor {
  WindowsResumeTextExtractor(this._ocrChannel);

  static const int maximumPages = 2;
  static const int minimumEmbeddedTextLength = 400;
  static const int maximumRenderedWidth = 2400;
  static const int maximumRenderedHeight = 3400;
  static const int minimumOcrImageSide = 1800;

  final MethodChannel _ocrChannel;

  @override
  Future<String> extractText(List<int> bytes, String fileName) async {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return _extractPdfText(bytes, fileName);
    }
    final recognized = await _recognize(Uint8List.fromList(bytes));
    return recognized.trim();
  }

  Future<String> _extractPdfText(List<int> bytes, String fileName) async {
    final document = await PdfDocument.openData(
      Uint8List.fromList(bytes),
      sourceName: fileName,
    );
    try {
      final pages = document.pages.take(maximumPages);
      final output = <String>[];
      for (final page in pages) {
        final embeddedText = (await page.loadText())?.fullText ?? '';
        if (embeddedText.trim().length >= minimumEmbeddedTextLength &&
            embeddedText.contains('@')) {
          output.add(embeddedText.trim());
          continue;
        }
        final scale = <double>[
          3.2,
          maximumRenderedWidth / page.width,
          maximumRenderedHeight / page.height,
        ].reduce((a, b) => a < b ? a : b);
        final width = (page.width * scale).round().clamp(
          1,
          maximumRenderedWidth,
        );
        final height = (page.height * scale).round().clamp(
          1,
          maximumRenderedHeight,
        );
        final rendered = await page.render(
          fullWidth: width.toDouble(),
          fullHeight: height.toDouble(),
          backgroundColor: 0xffffffff,
        );
        if (rendered == null) continue;
        try {
          final renderedImage = image.Image.fromBytes(
            width: rendered.width,
            height: rendered.height,
            bytes: rendered.pixels.buffer,
            bytesOffset: rendered.pixels.offsetInBytes,
            numChannels: 4,
            order: image.ChannelOrder.bgra,
          );
          final recognized = await _recognize(image.encodePng(renderedImage));
          final embedded = embeddedText.trim();
          output.add(embedded.isEmpty ? recognized : '$embedded\n$recognized');
        } finally {
          rendered.dispose();
        }
      }
      return output.where((text) => text.trim().isNotEmpty).join('\n\n');
    } finally {
      await document.dispose();
    }
  }

  Future<String> _recognize(Uint8List imageBytes) async {
    final decoded = image.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('The resume image could not be decoded.');
    }
    final oriented = image.bakeOrientation(decoded);
    final grayscale = image.grayscale(oriented);
    final enhanced = image.adjustColor(grayscale, contrast: 1.2);
    final longestSide = enhanced.width > enhanced.height
        ? enhanced.width
        : enhanced.height;
    final scale = longestSide > maximumRenderedWidth
        ? maximumRenderedWidth / longestSide
        : longestSide < minimumOcrImageSide
        ? (minimumOcrImageSide / longestSide).clamp(1, 1.8)
        : 1.0;
    final prepared = scale == 1
        ? enhanced
        : image.copyResize(
            enhanced,
            width: (enhanced.width * scale).round(),
            height: (enhanced.height * scale).round(),
            interpolation: image.Interpolation.cubic,
          );
    final text = await _ocrChannel.invokeMethod<String>(
      'recognizeText',
      image.encodePng(prepared),
    );
    if (text != null && text.trim().isNotEmpty) return text;
    // Contrast boosting can wash out light text; retry on the original image.
    final fallback = await _ocrChannel.invokeMethod<String>(
      'recognizeText',
      image.encodePng(oriented),
    );
    return fallback ?? '';
  }
}
