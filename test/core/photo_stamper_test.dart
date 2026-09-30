import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:urban_resilience/core/utils/photo_stamper.dart';

/// Creates a small solid-color PNG on disk and returns its file.
Future<File> _createTestImage(
  Directory dir, {
  int width = 200,
  int height = 150,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3399FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  final file = File('${dir.path}/source.png');
  await file.writeAsBytes(
    data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('photo_stamper_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('produces a compressed JPEG file next to the source image', () async {
    final source = await _createTestImage(tempDir);

    final result = await PhotoStamper.stampCoordinates(
      source: source,
      latitude: 5.3167,
      longitude: -4.0333,
      capturedAt: DateTime(2026, 1, 15, 10, 30),
    );

    expect(await result.exists(), isTrue);
    expect(result.path, endsWith('.gps.jpg'));

    // A valid JPEG file starts with the standard JPEG signature bytes.
    final bytes = await result.readAsBytes();
    const jpegSignature = [0xFF, 0xD8, 0xFF];
    expect(bytes.sublist(0, 3), jpegSignature);
  });

  test('keeps the original image dimensions', () async {
    final source = await _createTestImage(
      tempDir,
      width: 320,
      height: 240,
    );

    final result = await PhotoStamper.stampCoordinates(
      source: source,
      latitude: 0,
      longitude: 0,
    );

    final bytes = await result.readAsBytes();
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
    );
    final frame = await codec.getNextFrame();

    expect(frame.image.width, 320);
    expect(frame.image.height, 240);

    frame.image.dispose();
    codec.dispose();
  });

  test('does not modify the source file in place', () async {
    final source = await _createTestImage(tempDir);
    final originalBytes = await source.readAsBytes();

    await PhotoStamper.stampCoordinates(
      source: source,
      latitude: 5.3167,
      longitude: -4.0333,
    );

    final unchangedBytes = await source.readAsBytes();
    expect(unchangedBytes, originalBytes);
  });
}
