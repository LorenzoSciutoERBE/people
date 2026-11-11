import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Replaces native chooser dialogs while exercising actual file reads/writes.
class TestFilePicker extends FilePickerPlatform {
  TestFilePicker({required this.directory});

  final Directory directory;
  File? selected;
  File? exported;
  bool cancelSave = false;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => selected == null ? null : _TestPlatformFile(selected!);

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    String? dialogTitle,
    String? initialDirectory,
    void Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (cancelSave) return null;
    exported = File('${directory.path}/$fileName');
    await exported!.writeAsBytes(bytes, flush: true);
    return exported!.uri;
  }
}

final class _TestPlatformFile extends PlatformFile {
  _TestPlatformFile(this.file);

  final File file;

  @override
  String get name => file.uri.pathSegments.last;

  @override
  Uri get uri => file.uri;

  @override
  Never get xFile => throw UnsupportedError('The test does not use XFile.');

  @override
  int? lengthSync() => file.lengthSync();

  @override
  Future<int?> length() => file.length();

  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      file.openRead().map(Uint8List.fromList);
}
