import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/artisan_profile_provider.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/widgets/artisan_avatar.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_storage_service.dart';
import 'package:kriyo_artisan_app/shared/profile_photo/profile_photo_theme.dart';
import 'package:kriyo_artisan_app/shared/widgets/customer_avatar.dart';

Future<File> createTestImageFile(String filename, {int width = 100, int height = 100, Color color = const Color(0xFF9E4A28)}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );
  final paint = Paint()..color = color;
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

  late Directory fakeAppDocsDir;
  late File sourceImageFile;

  setUpAll(() async {
    fakeAppDocsDir = Directory('${Directory.systemTemp.path}/kriyo_test_docs_${DateTime.now().microsecondsSinceEpoch}');
    await fakeAppDocsDir.create(recursive: true);

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return fakeAppDocsDir.path;
    });

    sourceImageFile = await createTestImageFile('source_test_avatar.png');
  });

  tearDownAll(() async {
    try {
      if (await fakeAppDocsDir.exists()) {
        await fakeAppDocsDir.delete(recursive: true);
      }
      if (await sourceImageFile.exists()) {
        await sourceImageFile.delete();
      }
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Requirement 1 & 2: Permanent Storage & App Lifecycle Survival', () {
    test('savePermanentPhoto copies photo to permanent documents directory and returns valid path', () async {
      final permanentPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'patron_101',
        role: ProfilePhotoRole.customer,
      );

      expect(permanentPath, isNotNull);
      expect(permanentPath, contains('kriyo_profile_photos'));
      expect(permanentPath, contains('customer_profile_patron_101'));

      final permanentFile = File(permanentPath);
      expect(permanentFile.existsSync(), isTrue);
      expect(permanentFile.lengthSync(), greaterThan(0));
      expect(permanentFile.readAsBytesSync(), equals(sourceImageFile.readAsBytesSync()));
    });

    test('Permanent photo survives simulated app kill and reload via UserSessionNotifier.loadFromStorage', () async {
      // 1. Save customer photo
      final savedPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'patron_202',
        role: ProfilePhotoRole.customer,
      );

      // 2. Set up session and save
      final container1 = ProviderContainer();
      final notifier1 = container1.read(sessionProvider.notifier);
      notifier1.loginAsCustomer(
        mobileNumber: '+91 98765 43210',
        name: 'Aarav Patel',
      );
      notifier1.updateCustomerPhoto(savedPath);
      await notifier1.saveToStorage();
      container1.dispose();

      // 3. Simulate new app process cold start
      final container2 = ProviderContainer();
      final notifier2 = container2.read(sessionProvider.notifier);
      await notifier2.loadFromStorage();
      final restoredSession = container2.read(sessionProvider);

      expect(restoredSession.customerPhotoPath, equals(savedPath));
      expect(File(restoredSession.customerPhotoPath!).existsSync(), isTrue);
      expect(restoredSession.customerName, equals('Aarav Patel'));
      container2.dispose();
    });

    test('Artisan photo survives simulated app restart and reload via ArtisanProfileProvider', () async {
      final container1 = ProviderContainer();
      final defaultArtisanId = container1.read(artisanProfileProvider).artisanId;
      final savedPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: defaultArtisanId,
        role: ProfilePhotoRole.artisan,
      );

      await container1.read(artisanProfileProvider.notifier).setProfileImage(savedPath);
      container1.dispose();

      // Cold reload into new container
      final container2 = ProviderContainer();
      final notifier2 = container2.read(artisanProfileProvider.notifier);
      await notifier2.reloadFromPrefs();
      final reloadedArtisan = container2.read(artisanProfileProvider);
      expect(reloadedArtisan.profileImagePath, equals(savedPath));
      expect(reloadedArtisan.hasCustomPhoto, isTrue);
      container2.dispose();
    });
  });

  group('Requirement 3: Role & User Isolation', () {
    test('Customer A and Customer B have completely isolated photos', () async {
      final imgA = await createTestImageFile('user_a.png', color: const Color(0xFF123456));
      final imgB = await createTestImageFile('user_b.png', color: const Color(0xFF654321));

      final pathA = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: imgA,
        userId: 'customer_alpha',
        role: ProfilePhotoRole.customer,
      );

      final pathB = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: imgB,
        userId: 'customer_beta',
        role: ProfilePhotoRole.customer,
      );

      expect(pathA, isNot(equals(pathB)));

      final fetchedA = await ProfilePhotoStorageService.getPermanentPhotoPath(
        userId: 'customer_alpha',
        role: ProfilePhotoRole.customer,
      );
      final fetchedB = await ProfilePhotoStorageService.getPermanentPhotoPath(
        userId: 'customer_beta',
        role: ProfilePhotoRole.customer,
      );

      expect(fetchedA, equals(pathA));
      expect(fetchedB, equals(pathB));

      await imgA.delete();
      await imgB.delete();
    });

    test('Customer role and Artisan role photos are isolated for the same userId', () async {
      final customerPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'multi_role_user_404',
        role: ProfilePhotoRole.customer,
      );

      final artisanPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'multi_role_user_404',
        role: ProfilePhotoRole.artisan,
      );

      expect(customerPath, isNot(equals(artisanPath)));
      expect(customerPath, contains('customer_profile'));
      expect(artisanPath, contains('artisan_profile'));

      final verifiedCust = await ProfilePhotoStorageService.getPermanentPhotoPath(
        userId: 'multi_role_user_404',
        role: ProfilePhotoRole.customer,
      );
      final verifiedArtisan = await ProfilePhotoStorageService.getPermanentPhotoPath(
        userId: 'multi_role_user_404',
        role: ProfilePhotoRole.artisan,
      );

      expect(verifiedCust, equals(customerPath));
      expect(verifiedArtisan, equals(artisanPath));
    });
  });

  group('Requirement 4 & 5: Safe Replacement & Old File Cleanup', () {
    test('Replacing photo writes new file and deletes old file safely', () async {
      final firstPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'replace_user_505',
        role: ProfilePhotoRole.customer,
      );
      expect(File(firstPath).existsSync(), isTrue);

      final secondSource = await createTestImageFile('second_source.png', color: const Color(0xFF44AA88));
      final secondPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: secondSource,
        userId: 'replace_user_505',
        role: ProfilePhotoRole.customer,
      );

      expect(secondPath, isNot(equals(firstPath)));
      expect(File(secondPath).existsSync(), isTrue);
      // Old file should be deleted
      expect(File(firstPath).existsSync(), isFalse);

      await secondSource.delete();
    });

    test('removePermanentPhoto deletes file and clears preferences', () async {
      final path = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'delete_user_606',
        role: ProfilePhotoRole.customer,
      );
      expect(File(path).existsSync(), isTrue);

      await ProfilePhotoStorageService.removePermanentPhoto(
        userId: 'delete_user_606',
        role: ProfilePhotoRole.customer,
      );

      expect(File(path).existsSync(), isFalse);
      final stored = await ProfilePhotoStorageService.getPermanentPhotoPath(
        userId: 'delete_user_606',
        role: ProfilePhotoRole.customer,
      );
      expect(stored, isNull);
    });
  });

  group('Requirement 6: Missing / Stale File Handling & Fallbacks', () {
    test('getPermanentPhotoPath cleans stale reference if file was deleted externally', () async {
      final path = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'stale_user_707',
        role: ProfilePhotoRole.artisan,
      );

      // Externally delete the file to simulate file corruption / cleanup
      await File(path).delete();
      expect(File(path).existsSync(), isFalse);

      final recovered = await ProfilePhotoStorageService.getPermanentPhotoPath(
        userId: 'stale_user_707',
        role: ProfilePhotoRole.artisan,
      );
      expect(recovered, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('kriyo_profile_photo_artisan_stale_user_707'), isNull);
    });

    test('UserSessionNotifier ignores non-existent photo path during loadFromStorage', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kriyo_user_id', 'ghost_user');
      await prefs.setString('kriyo_customer_photo_path', '/fake/non/existent/path.png');

      final container = ProviderContainer();
      final notifier = container.read(sessionProvider.notifier);
      await notifier.loadFromStorage();

      final session = container.read(sessionProvider);
      expect(session.customerPhotoPath, isNull);
      container.dispose();
    });

    test('ArtisanProfileModel.hasCustomPhoto returns false if file does not exist', () {
      const model = ArtisanProfileModel(
        name: 'Master Weaver',
        craftSpecialty: 'Kanchipuram Silk',
        profileImagePath: '/non/existent/avatar.png',
      );
      expect(model.hasCustomPhoto, isFalse);
    });
  });

  group('Requirement 7 & 8: UI Avatar Widgets Fallback & Real Rendering', () {
    testWidgets('CustomerAvatar renders initials fallback gracefully without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerAvatar(
              imagePath: null,
              displayName: 'Priya Sharma',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('CustomerAvatar renders Image.file when valid permanent file is supplied', (tester) async {
      final savedPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'ui_avatar_user_808',
        role: ProfilePhotoRole.customer,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerAvatar(
              imagePath: savedPath,
              displayName: 'Meera Bai',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('M'), findsNothing);
    });

    testWidgets('ArtisanAvatar renders default icon when photo is missing and Image when photo exists', (tester) async {
      // 1. Missing photo
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtisanAvatar(
              imagePath: null,
              size: 60,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.person), findsOneWidget);

      // 2. Real permanent photo
      final savedPath = await ProfilePhotoStorageService.savePermanentPhoto(
        sourceFile: sourceImageFile,
        userId: 'ui_artisan_909',
        role: ProfilePhotoRole.artisan,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtisanAvatar(
              imagePath: savedPath,
              size: 60,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
