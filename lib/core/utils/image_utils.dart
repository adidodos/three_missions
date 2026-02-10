import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Compresses and resizes image, removes EXIF data.
/// Returns compressed file path.
Future<File?> compressImage(File file, {int maxWidth = 1080, int quality = 85}) async {
  try {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: maxWidth,
      minHeight: maxWidth,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false, // Remove EXIF data
    );

    if (result == null) return null;
    return File(result.path);
  } catch (e) {
    return null;
  }
}

/// Compresses image bytes directly.
Future<Uint8List?> compressImageBytes(
  Uint8List bytes, {
  int maxWidth = 1080,
  int quality = 85,
}) async {
  try {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxWidth,
      minHeight: maxWidth,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    return result;
  } catch (e) {
    return null;
  }
}
