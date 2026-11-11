import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'package:pdfrx/pdfrx.dart';

import '../../domain/repositories/resume_text_extractor.dart';

class WindowsResumeTextExtractor implements ResumeTextExtractor {
  const WindowsResumeTextExtractor(this._ocrChannel);

  static const int minimumEmbeddedTextLength = 40;
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
      final output = <String>[];
      for (final page in document.pages) {
        final embeddedText = (await page.loadText())?.fullText ?? '';
        if (_hasUsableEmbeddedText(embeddedText)) {
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
        if (rendered == null) {
          throw const FormatException(
            'The resume PDF page could not be rendered.',
          );
        }
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
          output.add(recognized);
        } finally {
          rendered.dispose();
        }
      }
      return output.where((text) => text.trim().isNotEmpty).join('\n\n');
    } finally {
      await document.dispose();
    }
  }

  bool _hasUsableEmbeddedText(String text) {
    final trimmed = text.trim();
    if (trimmed.length < minimumEmbeddedTextLength) return false;
    final letters = RegExp(r'\p{L}', unicode: true).allMatches(trimmed).length;
    final replacementCharacters = '\uFFFD'.allMatches(trimmed).length;
    return letters >= minimumEmbeddedTextLength ~/ 2 &&
        replacementCharacters / trimmed.length < 0.01;
  }

  Future<String> _recognize(Uint8List imageBytes) async {
    final decoded = image.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('The resume image could not be decoded.');
    }
    final oriented = image.bakeOrientation(decoded);
    final longestSide = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final maximumWidth = oriented.width > oriented.height
        ? maximumRenderedHeight
        : maximumRenderedWidth;
    final maximumHeight = oriented.width > oriented.height
        ? maximumRenderedWidth
        : maximumRenderedHeight;
    final fitScale = <double>[
      maximumWidth / oriented.width,
      maximumHeight / oriented.height,
    ].reduce((a, b) => a < b ? a : b);
    final scale = fitScale < 1
        ? fitScale
        : longestSide < minimumOcrImageSide
        ? (minimumOcrImageSide / longestSide).clamp(1, 1.8)
        : 1.0;
    final prepared = scale == 1
        ? oriented
        : image.copyResize(
            oriented,
            width: (oriented.width * scale).round(),
            height: (oriented.height * scale).round(),
            interpolation: image.Interpolation.cubic,
          );
    final text = await _recognizePrepared(prepared);
    if (text.trim().isNotEmpty) return text;
    // Keep source colors on the first pass; enhancement can erase light text.
    final enhanced = image.adjustColor(
      image.grayscale(prepared),
      contrast: 1.2,
    );
    return _recognizePrepared(enhanced);
  }

  Future<String> _recognizePrepared(image.Image prepared) async {
    final text = await _ocrChannel.invokeMethod<String>(
      'recognizeText',
      image.encodePng(prepared),
    );
    if (text == null) {
      throw PlatformException(
        code: 'ocr_invalid_response',
        message: 'Windows OCR did not return a recognition result.',
      );
    }
    return text;
  }
}
