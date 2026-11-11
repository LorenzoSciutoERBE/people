import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:people/features/candidate_management/data/datasources/windows_resume_text_extractor.dart';
import 'package:people/features/candidate_management/domain/usecases/parse_resume_contact.dart';
import 'package:people/l10n/app_localizations.dart';

Uint8List _textPdf(List<List<String>> pages) {
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Count ${pages.length} /Kids ['
        '${List.generate(pages.length, (index) => '${4 + index * 2} 0 R').join(' ')}'
        '] >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  for (var index = 0; index < pages.length; index++) {
    final stream =
        'BT /F1 18 Tf 24 TL 50 780 Td '
        '${pages[index].map((line) => '($line) Tj T*').join(' ')} ET';
    objects.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Resources << /Font << /F1 3 0 R >> >> '
      '/Contents ${5 + index * 2} 0 R >>',
    );
    objects.add(
      '<< /Length ${ascii.encode(stream).length} >>\nstream\n$stream\nendstream',
    );
  }
  final output = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[0];
  for (var index = 0; index < objects.length; index++) {
    offsets.add(ascii.encode(output.toString()).length);
    output.write('${index + 1} 0 obj\n${objects[index]}\nendobj\n');
  }
  final xref = ascii.encode(output.toString()).length;
  output.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets.skip(1)) {
    output.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  output.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xref\n%%EOF\n',
  );
  return Uint8List.fromList(ascii.encode(output.toString()));
}

Uint8List _scannedPdf(Uint8List png) {
  final decoded = image.decodePng(png);
  if (decoded == null) throw StateError('The test scan could not be decoded.');
  final jpeg = image.encodeJpg(decoded, quality: 95);
  const content =
      'q 595 0 0 842 0 0 cm /Scan Do Q '
      'BT /F1 8 Tf 20 20 Td (SCAN MARKER) Tj ET';
  final objects = <List<int>>[
    ascii.encode('<< /Type /Catalog /Pages 2 0 R >>'),
    ascii.encode('<< /Type /Pages /Count 1 /Kids [4 0 R] >>'),
    ascii.encode('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'),
    ascii.encode(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Resources << /Font << /F1 3 0 R >> /XObject << /Scan 6 0 R >> >> '
      '/Contents 5 0 R >>',
    ),
    ascii.encode(
      '<< /Length ${content.length} >>\nstream\n$content\nendstream',
    ),
    [
      ...ascii.encode(
        '<< /Type /XObject /Subtype /Image /Width ${decoded.width} '
        '/Height ${decoded.height} /ColorSpace /DeviceRGB '
        '/BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\nstream\n',
      ),
      ...jpeg,
      ...ascii.encode('\nendstream'),
    ],
  ];
  final output = BytesBuilder()..add(ascii.encode('%PDF-1.4\n'));
  final offsets = <int>[];
  for (var index = 0; index < objects.length; index++) {
    offsets.add(output.length);
    output
      ..add(ascii.encode('${index + 1} 0 obj\n'))
      ..add(objects[index])
      ..add(ascii.encode('\nendobj\n'));
  }
  final xref = output.length;
  output.add(
    ascii.encode('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n'),
  );
  for (final offset in offsets) {
    output.add(
      ascii.encode('${offset.toString().padLeft(10, '0')} 00000 n \n'),
    );
  }
  output.add(
    ascii.encode(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xref\n%%EOF\n',
    ),
  );
  return output.takeBytes();
}

Future<Uint8List> _resumeImage({String? content}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  final painter = TextPainter(
    text: TextSpan(
      text:
          content ??
          'ADA LOVELACE\n'
              'Software Engineer\n'
              'ada.lovelace@example.com\n'
              'Experience building reliable software systems.',
      style: const TextStyle(
        fontFamily: 'Arial',
        fontSize: 56,
        height: 1.6,
        color: Colors.black,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 1500);
  painter.paint(canvas, const Offset(100, 100));
  painter.dispose();
  final picture = recorder.endRecording();
  final raster = await picture.toImage(1800, 2400);
  picture.dispose();
  try {
    final data = await raster.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('The test resume image could not be encoded.');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    raster.dispose();
  }
}

void registerResumeOcrTests() {
  testWidgets('reads short digital PDF pages without invoking image OCR', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final extractor = WindowsResumeTextExtractor(
      const MethodChannel('test/ocr-must-not-be-invoked'),
    );
    final text = await extractor.extractText(
      _textPdf([
        ['ADA LOVELACE', 'Software engineer building reliable systems.'],
        [
          'EMPLOYMENT HISTORY',
          'Designed developer tools and distributed services.',
        ],
        [
          'EDUCATION AND CONTACT',
          'ada.lovelace@example.com',
          'Completed advanced mathematics studies.',
        ],
      ]),
      'digital-resume.pdf',
    );
    expect(text, contains('ADA LOVELACE'));
    expect(text, contains('EMPLOYMENT HISTORY'));
    expect(text, contains('ada.lovelace@example.com'));
    expect('ADA LOVELACE'.allMatches(text), hasLength(1));
    final contact = const ParseResumeContact()(text);
    expect(contact.firstName, 'Ada');
    expect(contact.lastName, 'Lovelace');
    expect(contact.email, 'ada.lovelace@example.com');
  });

  testWidgets('native Windows OCR preserves resume lines and contact details', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final extractor = WindowsResumeTextExtractor(
      const MethodChannel('people/resume_ocr'),
    );
    final text = await extractor.extractText(await _resumeImage(), 'scan.png');
    expect(
      text.split('\n').where((line) => line.isNotEmpty).length,
      greaterThanOrEqualTo(4),
    );
    final contact = const ParseResumeContact()(text);
    expect(contact.firstName, 'Ada');
    expect(contact.lastName, 'Lovelace');
    expect(contact.email, 'ada.lovelace@example.com');
  });

  testWidgets('reads a scanned PDF without appending its partial text layer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final extractor = WindowsResumeTextExtractor(
      const MethodChannel('people/resume_ocr'),
    );
    final text = await extractor.extractText(
      _scannedPdf(await _resumeImage()),
      'scanned-resume.pdf',
    );
    final contact = const ParseResumeContact()(text);
    expect(contact.firstName, 'Ada');
    expect(contact.lastName, 'Lovelace');
    expect(contact.email, 'ada.lovelace@example.com');
    expect('ADA LOVELACE'.allMatches(text), hasLength(1));
    expect('SCAN MARKER'.allMatches(text).length, lessThanOrEqualTo(1));
  });

  testWidgets(
    'automatic OCR recognizes Italian resumes without language selection',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final localization = lookupAppLocalizations(const Locale('it'));
      final bytes = await _resumeImage(
        content:
            'ADA LOVELACE\n'
            '${localization.candidateExperience}\n'
            'ada.lovelace@example.com\n'
            '${localization.ratingMotivation}',
      );
      const extractor = WindowsResumeTextExtractor(
        MethodChannel('people/resume_ocr'),
      );
      final text = await extractor.extractText(bytes, 'italian-resume.png');
      final contact = const ParseResumeContact()(text);
      expect(contact.firstName, 'Ada');
      expect(contact.lastName, 'Lovelace');
      expect(contact.email, 'ada.lovelace@example.com');
      expect(
        text.toLowerCase(),
        contains(localization.ratingMotivation.toLowerCase()),
      );
    },
  );
}
