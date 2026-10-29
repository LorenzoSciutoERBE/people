import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:people/features/candidate_management/data/datasources/windows_resume_text_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizes and enlarges source images before OCR', () async {
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
    expect(pixel.r, pixel.g);
    expect(pixel.g, pixel.b);
  });
}
