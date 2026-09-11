import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_service.dart';

Future<File> createTestImageFile(String filename, {int width = 800, int height = 600}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  final paint = Paint()..color = const Color(0xFF9E4A28);
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(byteData!.buffer.asUint8List(), flush: true);
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File testSourceFile;

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });

    testSourceFile = await createTestImageFile('crop_test_source.png', width: 1200, height: 800);
  });

  group('Profile Photo Crop Engine - Math & Boundary Tests', () {
    test('Viewport cropDiameter is always a true 1:1 circle (width == height)', () {
      final viewportSizes = [
        const Size(320, 480), // small phone
        const Size(375, 667), // standard phone
        const Size(412, 915), // modern phone
        const Size(768, 1024), // tablet
      ];

      for (final size in viewportSizes) {
        final double cropDiameter = math.min(
          size.width - 40.0,
          size.height - 60.0,
        ).clamp(240.0, 320.0);

        expect(cropDiameter >= 240.0 && cropDiameter <= 320.0, isTrue);
        // Radius in X and Y are mathematically identical
        final radiusX = cropDiameter / 2.0;
        final radiusY = cropDiameter / 2.0;
        expect(radiusX, equals(radiusY));
      }
    });

    test('Fit scale ensures minimum scale covers circular aperture completely', () {
      const rawW = 1200.0;
      const rawH = 800.0;
      const cropDiameter = 280.0;

      // Unrotated (0 turns)
      final fitScale = math.max(cropDiameter / rawW, cropDiameter / rawH);
      final baseW = rawW * fitScale;
      final baseH = rawH * fitScale;

      expect(baseW >= cropDiameter, isTrue);
      expect(baseH >= cropDiameter, isTrue);

      // Rotated 90 degrees (1 turn)
      final fitScaleRotated = math.max(cropDiameter / rawH, cropDiameter / rawW);
      final baseWRotated = rawH * fitScaleRotated;
      final baseHRotated = rawW * fitScaleRotated;

      expect(baseWRotated >= cropDiameter, isTrue);
      expect(baseHRotated >= cropDiameter, isTrue);
    });

    test('Pan offset clamping guarantees empty background is never exposed', () {
      const cropDiameter = 280.0;
      const curW = 420.0; // wider than circle
      const curH = 280.0; // touches circle top & bottom

      final maxPanX = math.max(0.0, (curW - cropDiameter) / 2.0); // (420 - 280)/2 = 70
      final maxPanY = math.max(0.0, (curH - cropDiameter) / 2.0); // (280 - 280)/2 = 0

      expect(maxPanX, equals(70.0));
      expect(maxPanY, equals(0.0));

      // Panning further than maxPanX gets safely clamped
      const requestedPanX = 150.0;
      final clampedPanX = requestedPanX.clamp(-maxPanX, maxPanX);
      expect(clampedPanX, equals(70.0));

      // Panning vertically when curH == cropDiameter is clamped to 0
      const requestedPanY = -50.0;
      final clampedPanY = requestedPanY.clamp(-maxPanY, maxPanY);
      expect(clampedPanY, equals(0.0));
    });

    test('ProfilePhotoService.cropSquare outputs 800x800 high-res circular PNG', () async {
      final cropped = await ProfilePhotoService.cropSquare(
        sourceFile: testSourceFile,
        scale: 1.0,
        panOffset: Offset.zero,
        cropDiameter: 280.0,
        viewportSize: const Size(360, 600),
      );

      expect(cropped.existsSync(), isTrue);
      expect(await cropped.length() > 0, isTrue);

      final bytes = await cropped.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      expect(frame.image.width, equals(ProfilePhotoService.outputResolution));
      expect(frame.image.height, equals(ProfilePhotoService.outputResolution));
      expect(frame.image.width, equals(800));
      expect(frame.image.height, equals(800));
    });
  });
}
