import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Incruste les coordonnées GPS et la date directement dans les pixels
/// de la photo, puis retourne un nouveau fichier PNG.
class PhotoStamper {
  const PhotoStamper._();

  static Future<File> stampCoordinates({
    required File source,
    required double latitude,
    required double longitude,
    DateTime? capturedAt,
  }) async {
    final bytes = await source.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Photo d'origine
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    // Texte à incruster
    final date = capturedAt ?? DateTime.now();
    final text = 'GPS : ${latitude.toStringAsFixed(6)}, '
        '${longitude.toStringAsFixed(6)}\n'
        '${_formatDate(date)}';

    final fontSize = (width * 0.035).clamp(18.0, 64.0);
    final padding = fontSize * 0.6;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - padding * 2);

    // Bandeau semi-transparent en bas de l'image
    final bandHeight = painter.height + padding * 2;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, height - bandHeight, width, bandHeight),
      ui.Paint()..color = const ui.Color(0xB3000000),
    );

    painter.paint(
      canvas,
      ui.Offset(padding, height - bandHeight + padding),
    );

    final picture = recorder.endRecording();
    final stamped = await picture.toImage(image.width, image.height);
    final data = await stamped.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    stamped.dispose();
    codec.dispose();

    if (data == null) {
      throw StateError('Impossible de générer la photo avec les coordonnées.');
    }

    final output = File('${source.path}.gps.png');
    await output.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return output;
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}
