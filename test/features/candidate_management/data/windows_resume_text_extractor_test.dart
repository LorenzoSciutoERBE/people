import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:people/features/candidate_management/data/datasources/windows_resume_text_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'preserves source colors and enlarges small images before OCR',
    () async {
      const channel = MethodChannel('test/resume_ocr');
      Uint8List? submittedImage;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            submittedImage = call.arguments as Uint8List;
            return 'recognized resume text';
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final source = image.Image(width: 300, height: 500);
      image.fill(source, color: image.ColorRgb8(230, 180, 120));
      final extractor = WindowsResumeTextExtractor(channel);
      final text = await extractor.extractText(
        image.encodePng(source),
        'resume.png',
      );

      expect(text, 'recognized resume text');
      final prepared = image.decodeImage(submittedImage!);
      expect(prepared, isNotNull);
      expect(prepared!.height, 900);
      expect(prepared.width, 540);
      final pixel = prepared.getPixel(20, 20);
      expect(pixel.r, 230);
      expect(pixel.g, 180);
      expect(pixel.b, 120);
    },
  );

  test('preserves portrait document resolution', () async {
    const channel = MethodChannel('test/resume_ocr');
    Uint8List? submittedImage;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          submittedImage = call.arguments as Uint8List;
          return 'Recognized text';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final source = image.Image(width: 1200, height: 3000);
    await WindowsResumeTextExtractor(channel)
        .extractText(image.encodePng(source), 'portrait.png');
    final prepared = image.decodeImage(submittedImage!)!;
    expect(prepared.width, 1200);
    expect(prepared.height, 3000);
  });

  test('retries enhancement only when the original produces no text', () async {
    const channel = MethodChannel('test/resume_ocr');
    final submitted = <Uint8List>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          submitted.add(call.arguments as Uint8List);
          return submitted.length == 1 ? '' : 'Recovered text';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final source = image.Image(width: 300, height: 500);
    image.fill(source, color: image.ColorRgb8(230, 180, 120));
    final text = await WindowsResumeTextExtractor(channel)
        .extractText(image.encodePng(source), 'resume.png');
    expect(text, 'Recovered text');
    expect(submitted, hasLength(2));
    final firstPixel = image.decodeImage(submitted.first)!.getPixel(0, 0);
    final secondPixel = image.decodeImage(submitted.last)!.getPixel(0, 0);
    expect(firstPixel.r, isNot(firstPixel.g));
    expect(secondPixel.r, secondPixel.g);
    expect(secondPixel.g, secondPixel.b);
  });

  test(
    'reports a missing native OCR response rather than empty success',
    () async {
      const channel = MethodChannel('test/resume_ocr');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await expectLater(
        WindowsResumeTextExtractor(channel).extractText(
          image.encodePng(image.Image(width: 30, height: 50)),
          'resume.png',
        ),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'ocr_invalid_response',
          ),
        ),
      );
    },
  );
}
