import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/bounded_file.dart';
import 'score_parser.dart';

abstract final class PhotoService {
  static const maxPhotoBytes = 40 * 1024 * 1024;
  static const channel = MethodChannel('app.jws.tallybowl/vision');
  static Future<Directory> _imports() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'imports'),
  ).create(recursive: true);
  static Future<String> retain(Uint8List bytes) async {
    if (bytes.length > maxPhotoBytes) {
      throw const FormatException('Choose a photo smaller than 40 MB.');
    }
    final digest = sha256.convert(bytes).toString();
    final file = File(p.join((await _imports()).path, '$digest.image'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Check before allocating, and cap the stream too in case a file changes
  /// after its size was checked. macOS files are not resized by image_picker.
  static Future<Uint8List> readPhoto(XFile file) => readBoundedFile(
    file,
    maxBytes: maxPhotoBytes,
    tooLargeMessage: 'Choose a photo smaller than 40 MB.',
  );

  static Future<String?> pick({required bool camera}) async {
    if (Platform.isMacOS && camera) {
      final bytes = await channel.invokeMethod<Uint8List>('capturePhoto');
      return bytes == null ? null : retain(bytes);
    }
    if (Platform.isMacOS) {
      const type = XTypeGroup(
        label: 'Scoreboard photos',
        extensions: ['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'],
        uniformTypeIdentifiers: ['public.image'],
      );
      final file = await openFile(acceptedTypeGroups: [type]);
      return file == null ? null : retain(await readPhoto(file));
    }
    final image = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      requestFullMetadata: false,
    );
    return image == null ? null : retain(await readPhoto(image));
  }

  static Future<List<RecognizedLine>> recognize(String path) async {
    final bytes = await readPhoto(XFile(path));
    final output = await channel.invokeMethod<List<dynamic>>('recognizeText', {
      'bytes': bytes,
    });
    return (output ?? [])
        .map((v) => RecognizedLine.fromJson(v as Map))
        .toList();
  }

  static Future<String?> recover() async {
    if (!Platform.isAndroid) return null;
    final response = await ImagePicker().retrieveLostData();
    if (response.exception != null) throw response.exception!;
    final file = response.files?.firstOrNull;
    return file == null ? null : retain(await readPhoto(file));
  }

  static Future<void> remove(String? source) async {
    if (source == null) return;
    final directory = await _imports();
    if (!p.isWithin(directory.path, source)) return;
    final file = File(source);
    if (await file.exists()) await file.delete();
  }

  static Future<void> cleanOrphans(String? keepPath) async {
    final directory = await _imports();
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is File && entry.path != keepPath) await entry.delete();
    }
  }
}
