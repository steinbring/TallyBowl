import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Providers and files can change after length() is read. Bound both the
/// declared size and actual bytes before callers decode or parse the content.
Future<Uint8List> readBoundedFile(
  XFile file, {
  required int maxBytes,
  required String tooLargeMessage,
}) async {
  if (await file.length() > maxBytes) throw FormatException(tooLargeMessage);
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in file.openRead()) {
    if (bytes.length + chunk.length > maxBytes) {
      throw FormatException(tooLargeMessage);
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
