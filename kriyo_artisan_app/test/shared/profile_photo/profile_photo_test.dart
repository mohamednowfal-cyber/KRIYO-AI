import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/artisan_profile_provider.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/widgets/artisan_photo_sheet.dart';
import 'package:kriyo_artisan_app/features/buyer/profile/widgets/customer_photo_sheet.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_crop_screen.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_preview_screen.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_service.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_theme.dart';

/// Helper to generate a valid test image file on disk using dart:ui
Future<File> createTestImageFile(String filename, {int width = 200, int height = 200}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );
  final paint = Paint()..color = const Color(0xFF9E4A28);
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File sharedTestImage;

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });

    sharedTestImage = await createTestImageFile('shared_profile_test.png', width: 250, height: 250);
  });

  tearDownAll(() async {
    try {
      if (await sharedTestImage.exists()) {
        await sharedTestImage.delete();
      }
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. ProfilePhotoTheme Unit Tests', () {
    test('Artisan theme provides terracotta, warm ivory, and deep craft brown styling', () {
      final theme = ProfilePhotoTheme.artisan;
      expect(theme.role, equals(ProfilePhotoRole.artisan));
      expect(theme.primaryColor, equals(const Color(0xFF9E4A28)));
      expect(theme.backgroundColor, equals(const Color(0xFFFBF7EF)));
      expect(theme.textColor, equals(const Color(0xFF3D2115)));
      expect(theme.accentColor, equals(const Color(0xFFC67D0A)));
      expect(theme.roleName, equals('Artisan'));
    });

    test('Customer theme provides customer commerce styling', () {
      final theme = ProfilePhotoTheme.customer;
      expect(theme.role, equals(ProfilePhotoRole.customer));
      expect(theme.primaryColor, equals(const Color(0xFF9E4A28)));
      expect(theme.backgroundColor, equals(const Color(0xFFFBF7EF)));
      expect(theme.roleName, equals('Patron'));
    });
  });

  group('2. ProfilePhotoService Validation & Cropping Tests', () {
    test('validateImageFile rejects non-existent and empty files', () async {
      final nonExistent = File('${Directory.systemTemp.path}/non_existent_${DateTime.now().microsecondsSinceEpoch}.png');
      final resultNonExistent = await ProfilePhotoService.validateImageFile(nonExistent);
      expect(resultNonExistent.isValid, isFalse);

      final emptyFile = File('${Directory.systemTemp.path}/empty_${DateTime.now().microsecondsSinceEpoch}.png');
      await emptyFile.writeAsBytes([]);
      final resultEmpty = await ProfilePhotoService.validateImageFile(emptyFile);
      expect(resultEmpty.isValid, isFalse);
      expect(resultEmpty.errorMessage, contains('empty'));
      await emptyFile.delete();
    });

    test('validateImageFile accepts valid decodable image files with dimensions', () async {
      final result = await ProfilePhotoService.validateImageFile(sharedTestImage);
      expect(result.isValid, isTrue);
      expect(result.width, equals(250));
      expect(result.height, equals(250));
      expect(result.fileSizeBytes, greaterThan(0));
    });

    test('cropSquare produces high-resolution 1:1 square output file (800x800)', () async {
      final croppedFile = await ProfilePhotoService.cropSquare(
        sourceFile: sharedTestImage,
        scale: 1.2,
        panOffset: const Offset(10, -5),
        cropDiameter: 280,
        viewportSize: const Size(360, 480),
        quarterTurns: 1, // 90 degree rotation
        mirrorHorizontally: true, // front camera mirroring test
      );

      expect(await croppedFile.exists(), isTrue);
      expect(await croppedFile.length(), greaterThan(0));

      // Verify the output dimensions are 800x800
      final validation = await ProfilePhotoService.validateImageFile(croppedFile);
      expect(validation.isValid, isTrue);
      expect(validation.width, equals(ProfilePhotoService.outputResolution));
      expect(validation.height, equals(ProfilePhotoService.outputResolution));

      await croppedFile.delete();
    });
  });

  group('3. ProfilePhotoCropScreen Widget Tests', () {
    testWidgets('Renders Crop Profile Photo UI, circular guide, controls, and responds to interactions',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePhotoCropScreen(
                        sourceFile: sharedTestImage,
                        theme: ProfilePhotoTheme.artisan,
                      ),
                    ),
                  );
                },
                child: const Text('Open Crop'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Crop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Crop Profile Photo'), findsOneWidget);
      expect(find.text('Drag and pinch to fit your face inside the circle'), findsOneWidget);
      expect(find.text('Reset'), findsNWidgets(2)); // app bar action + tool button
      expect(find.text('Zoom -'), findsOneWidget);
      expect(find.text('Zoom +'), findsOneWidget);
      expect(find.text('Rotate'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Use Photo'), findsOneWidget);

      // Tap Zoom +
      await tester.tap(find.text('Zoom +'));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap Rotate
      await tester.tap(find.text('Rotate'));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap Reset
      await tester.tap(find.text('Reset').first);
      await tester.pump(const Duration(milliseconds: 50));

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Open Crop'), findsOneWidget);
    });
  });

  group('4. ProfilePhotoPreviewScreen Widget Tests', () {
    testWidgets('Renders circular preview with Choose Another and Use This Photo buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePhotoPreviewScreen(
                        imageFile: sharedTestImage,
                        theme: ProfilePhotoTheme.customer,
                      ),
                    ),
                  );
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Profile Photo Preview'), findsOneWidget);
      expect(find.text('Looking Great!'), findsOneWidget);
      expect(find.text('Choose Another'), findsOneWidget);
      expect(find.text('Use This Photo'), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);

      // Tap Use This Photo -> triggers upload state
      await tester.tap(find.text('Use This Photo'));
      await tester.pump();
      expect(find.text('Uploading profile photo...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('✓ Profile photo updated'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    });
  });

  group('5. Role Integration & State Update Tests', () {
    testWidgets('CustomerPhotoSheet displays bottom sheet options and updates state',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => CustomerPhotoSheet.show(context, ref),
                    child: const Text('Open Customer Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Customer Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel closes sheet
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Add Profile Photo'), findsNothing);
    });

    testWidgets('CustomerPhotoSheet shows Remove Photo when photo is present',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sessionProvider.notifier).updateCustomerPhoto(sharedTestImage.path);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => CustomerPhotoSheet.show(context, ref),
                    child: const Text('Open Customer Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Customer Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Remove Photo'), findsOneWidget);

      // Tap Remove Photo
      await tester.tap(find.text('Remove Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify customer photo is removed in sessionProvider
      expect(container.read(sessionProvider).customerPhotoPath, isNull);
    });

    testWidgets('ArtisanPhotoSheet shows options and updates artisan profile state',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(artisanProfileProvider.notifier).setProfileImage(sharedTestImage.path);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => ArtisanPhotoSheet.show(context, ref),
                    child: const Text('Open Artisan Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Artisan Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);

      // Tap Remove Photo
      await tester.tap(find.text('Remove Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify photo is removed from artisanProfileProvider
      expect(container.read(artisanProfileProvider).hasCustomPhoto, isFalse);
    });
  });
}
