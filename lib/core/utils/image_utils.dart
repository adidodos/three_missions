import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

bool _timestampFontsLoaded = false;

Future<void> _ensureTimestampFontsLoaded() async {
  if (_timestampFontsLoaded) return;
  try {
    final timeLoader = FontLoader('RobotoThin');
    timeLoader.addFont(rootBundle.load('assets/fonts/Roboto-Thin.ttf'));
    await timeLoader.load();

    final dateLoader = FontLoader('NotoSansKR');
    dateLoader.addFont(rootBundle.load('assets/fonts/NotoSansKR-Light.ttf'));
    await dateLoader.load();

    _timestampFontsLoaded = true;
    debugPrint('[ImageUtils] Timestamp fonts loaded');
  } catch (e) {
    debugPrint('[ImageUtils] Font loading failed (will use fallback): $e');
  }
}

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
      keepExif: false,
    );

    if (result == null) {
      debugPrint('[ImageUtils] compressImage: compress returned null for ${file.path}');
      return null;
    }
    final compressed = File(result.path);
    debugPrint('[ImageUtils] compressImage: ${file.lengthSync()} → ${compressed.lengthSync()} bytes');
    return compressed;
  } catch (e, st) {
    debugPrint('[ImageUtils] compressImage failed: $e\n$st');
    return null;
  }
}

/// Stamps a beautifully designed timestamp onto the image (center).
/// Time is displayed large with Roboto Thin + glow, date below with NotoSansKR Light.
/// Text is burned into the image pixels (no UI overlay).
Future<File?> stampTimestamp(File imageFile, DateTime timestamp) async {
  try {
    await _ensureTimestampFontsLoaded();

    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final original = frame.image;

    final width = original.width.toDouble();
    final height = original.height.toDouble();

    // Font sizes scaled to image width
    final timeFontSize = (width * 0.10).clamp(44.0, 150.0);
    final dateFontSize = (width * 0.050).clamp(22.0, 72.0);
    final gap = dateFontSize * 0.7;

    // Format: time "04:33", date "2021년 1월 15일 (금)"
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[timestamp.weekday - 1];
    final timeLine =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final dateLine =
        '${timestamp.year}년 ${timestamp.month}월 ${timestamp.day}일 ($weekday)';

    // ── Time style: Roboto Thin, large, white, with glow ──────────────────
    final timeStyle = TextStyle(
      fontFamily: 'RobotoThin',
      fontSize: timeFontSize,
      fontWeight: FontWeight.w100,
      color: const ui.Color(0xFFFFFFFF),
      letterSpacing: timeFontSize * 0.06,
      shadows: [
        // Glow layers (centered, increasing blur → halo effect)
        Shadow(
          offset: Offset.zero,
          blurRadius: timeFontSize * 0.50,
          color: const ui.Color(0x55FFFFFF),
        ),
        Shadow(
          offset: Offset.zero,
          blurRadius: timeFontSize * 0.25,
          color: const ui.Color(0x75FFFFFF),
        ),
        // Drop shadow for readability on bright backgrounds
        Shadow(
          offset: Offset(timeFontSize * 0.02, timeFontSize * 0.03),
          blurRadius: timeFontSize * 0.08,
          color: const ui.Color(0xCC000000),
        ),
      ],
    );

    // ── Date style: NotoSansKR Light, smaller, soft white ─────────────────
    final dateStyle = TextStyle(
      fontFamily: 'NotoSansKR',
      fontSize: dateFontSize,
      fontWeight: FontWeight.w700,
      color: const ui.Color(0xDDFFFFFF),
      letterSpacing: dateFontSize * 0.025,
      shadows: [
        Shadow(
          offset: Offset(dateFontSize * 0.04, dateFontSize * 0.06),
          blurRadius: dateFontSize * 0.25,
          color: const ui.Color(0xAA000000),
        ),
      ],
    );

    // ── Measure text ───────────────────────────────────────────────────────
    final timePainter = TextPainter(
      text: TextSpan(text: timeLine, style: timeStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final datePainter = TextPainter(
      text: TextSpan(text: dateLine, style: dateStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final contentH = timePainter.height + gap + datePainter.height;

    // ── Position: center of image ──────────────────────────────────────────
    final cx = width / 2;
    final cy = height / 2;

    // ── Draw ───────────────────────────────────────────────────────────────
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Original image
    canvas.drawImage(original, ui.Offset.zero, ui.Paint());

    // Time text (centered horizontally, top of content block)
    final timeX = cx - timePainter.width / 2;
    final timeY = cy - contentH / 2;
    timePainter.paint(canvas, ui.Offset(timeX, timeY));

    // Date text (centered horizontally, below time)
    final dateX = cx - datePainter.width / 2;
    final dateY = timeY + timePainter.height + gap;
    timePainter.dispose();
    datePainter.paint(canvas, ui.Offset(dateX, dateY));
    datePainter.dispose();

    // ── Encode to PNG → JPEG ───────────────────────────────────────────────
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(width.toInt(), height.toInt());
    final pngData = await rendered.toByteData(format: ui.ImageByteFormat.png);

    original.dispose();
    rendered.dispose();

    if (pngData == null) {
      debugPrint('[ImageUtils] stampTimestamp: toByteData returned null');
      return null;
    }

    final dir = await getTemporaryDirectory();
    final pngPath = '${dir.path}/${const Uuid().v4()}_stamped.png';
    final pngFile = File(pngPath);
    await pngFile.writeAsBytes(pngData.buffer.asUint8List());

    final jpegPath = '${dir.path}/${const Uuid().v4()}_stamped.jpg';
    final jpegResult = await FlutterImageCompress.compressAndGetFile(
      pngPath,
      jpegPath,
      quality: 90,
      format: CompressFormat.jpeg,
    );

    try {
      await pngFile.delete();
    } catch (_) {}

    if (jpegResult == null) {
      debugPrint('[ImageUtils] stampTimestamp: JPEG re-encode failed');
      return null;
    }

    final result = File(jpegResult.path);
    debugPrint('[ImageUtils] stampTimestamp: success (${result.lengthSync()} bytes)');
    return result;
  } catch (e, st) {
    debugPrint('[ImageUtils] stampTimestamp failed: $e\n$st');
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
  } catch (e, st) {
    debugPrint('[ImageUtils] compressImageBytes failed: $e\n$st');
    return null;
  }
}
