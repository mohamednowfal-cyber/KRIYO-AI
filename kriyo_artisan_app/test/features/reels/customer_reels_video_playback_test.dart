import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/reels/data/reel_storage_service.dart';
import 'package:kriyo_artisan_app/features/reels/models/reel_models.dart';
import 'package:kriyo_artisan_app/features/reels/presentation/customer/customer_craft_reels_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextTextureId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextTextureId++;
    return id;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 30),
      size: const Size(1080, 1920),
    ));
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox(width: 1080, height: 1920);
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KRIYO 10 Local Reel Assets Validation & Registration', () {
    const expectedVideoPaths = [
      'assets/Videos/A gift which is emotionally strong and loved by everyone_HD.mp4',
      'assets/Videos/Beautiful butterfly made out of paper_HD.mp4',
      'assets/Videos/Beautiful paper jhumar DIY crafts_HD.mp4',
      'assets/Videos/DIY waterfall card wheel of memories_HD.mp4',
      'assets/Videos/Easy wall hanging craft ideas_HD.mp4',
      'assets/Videos/Episode 5 of our DIY Diwali Decor Series is here!_HD.mp4',
      'assets/Videos/Poetry of hands_HD.mp4',
      'assets/Videos/Unique Paper Cup Wall Hanging Ideas __ Easy Paper Cup craft ideas __ Paper C_HD.mp4',
      'assets/Videos/Wait For The Result_HD.mp4',
      'assets/Videos/you need 2 rupees only for this gift idea_HD.mp4',
    ];

    test('All 10 video files exist on disk in assets/Videos/', () {
      for (final path in expectedVideoPaths) {
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'Missing video file on disk: $path');
        expect(file.lengthSync(), greaterThan(1000000),
            reason: 'Video file seems empty or corrupted: $path');
      }
    });

    test('pubspec.yaml explicitly registers all 10 video files', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final path in expectedVideoPaths) {
        expect(pubspec.contains(path), isTrue,
            reason: 'pubspec.yaml missing asset declaration for: $path');
      }
    });

    test('All 10 seed reels are mapped to unique, distinct video files', () {
      final reels = ReelStorageService.initial10AssetReels;
      expect(reels.length, equals(10));

      final mappedVideos = reels.map((r) => r.videoAsset).toSet();
      expect(mappedVideos.length, equals(10),
          reason: 'Every reel must have a distinct video asset!');

      for (int i = 0; i < 10; i++) {
        final reel = reels[i];
        expect(reel.videoAsset, equals(expectedVideoPaths[i]));
        expect(reel.artisanName.isNotEmpty, isTrue);
        expect(reel.craftName.isNotEmpty, isTrue);
        expect(reel.location.isNotEmpty, isTrue);
        expect(reel.description.isNotEmpty, isTrue);
        expect(reel.productId, isNotNull);
        expect(reel.productName, isNotNull);
        expect(reel.productPrice, greaterThan(0));
        expect(reel.learnCraftRoute, isNotNull);
        expect(reel.sourceTypeCategory, equals(ReelSourceType.asset));
      }
    });
  });

  group('Reel Model & Canonical Accessors', () {
    test('ArtisanReelItem canonical getters expose consistent properties', () {
      final reel = ArtisanReelItem(
        id: 'REL-UNIT-01',
        artisanId: 'ART-001',
        artisanName: 'Lakshmi Devi',
        artisanRole: '4th Gen Master Weaver',
        artisanAvatar: 'https://example.com/avatar.jpg',
        region: 'Kanchipuram, Tamil Nadu',
        videoUrl:
            'assets/Videos/A gift which is emotionally strong and loved by everyone_HD.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        caption: 'Generational love and artisan soul.',
        craftType: 'Folk Craft & Keepsake Story',
        technique: 'Handcrafted Miniature Art & Storytelling',
        audioTrackTitle: 'Original Studio Atmosphere • Lakshmi Devi',
        likesCount: 1420,
        commentsCount: 38,
        savesCount: 310,
        linkedProductId: 'KRY-PRD-01',
        linkedProductTitle: 'Handspun Kanchipuram Pure Silk Saree',
        linkedProductPrice: 14500,
        linkedCourseId: 'GRK-CRS-01',
        linkedCourseTitle: 'Mastering the Pit Loom',
        createdAt: DateTime.now(),
      );

      expect(reel.videoAsset,
          equals('assets/Videos/A gift which is emotionally strong and loved by everyone_HD.mp4'));
      expect(reel.artisanImage, equals('https://example.com/avatar.jpg'));
      expect(reel.craftName, equals('Folk Craft & Keepsake Story'));
      expect(reel.location, equals('Kanchipuram, Tamil Nadu'));
      expect(reel.description, equals('Generational love and artisan soul.'));
      expect(reel.productId, equals('KRY-PRD-01'));
      expect(reel.productName, equals('Handspun Kanchipuram Pure Silk Saree'));
      expect(reel.productPrice, equals(14500));
      expect(reel.likes, equals(1420));
      expect(reel.comments, equals(38));
      expect(reel.audioLabel, equals('Original Studio Atmosphere • Lakshmi Devi'));
      expect(reel.learnCraftRoute, equals('GRK-CRS-01'));
      expect(reel.sourceTypeCategory, equals(ReelSourceType.asset));
    });

    test('Network URLs correctly resolve sourceTypeCategory as network', () {
      final networkReel = ArtisanReelItem(
        id: 'REL-NET-01',
        artisanId: 'ART-002',
        artisanName: 'Ramesh',
        artisanRole: 'Potter',
        artisanAvatar: 'https://example.com/avatar.jpg',
        region: 'Jaipur',
        videoUrl: 'https://cdn.kriyo.art/reels/artisan_upload_01.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        caption: 'Clay pot creation',
        craftType: 'Terracotta',
        technique: 'Wheel throwing',
        createdAt: DateTime.now(),
      );

      expect(networkReel.sourceTypeCategory, equals(ReelSourceType.network));
    });
  });

  group('CustomerCraftReelsScreen UI & Interaction Tests', () {
    Widget buildScreen() {
      return const ProviderScope(
        child: MaterialApp(
          home: CustomerCraftReelsScreen(),
        ),
      );
    }

    testWidgets('Header displays Craft Stories 1/10 and mute toggle button',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Top header indicator
      expect(find.text('Craft Stories'), findsOneWidget);
      expect(find.text('1/10'), findsOneWidget);

      // Mute toggle speaker icon
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // Tap mute toggle
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      // Icon should switch to muted
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets('Displays Reel metadata: artisan name, product button, Gurukul button, and lore',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Artisan Name
      expect(find.text('Lakshmi Devi'), findsOneWidget);

      // Product CTA button with price
      expect(find.textContaining('View Product • ₹14500'), findsOneWidget);

      // Learn this craft Gurukul CTA button
      expect(find.text('Learn This Craft'), findsOneWidget);

      // Right action buttons
      expect(find.text('Lore'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Double tap triggers heart animation and likes the reel',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Initial likes
      expect(find.text('1420'), findsOneWidget);

      // Double tap on screen
      await tester.tap(find.byType(CustomerCraftReelsScreen));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(CustomerCraftReelsScreen));
      await tester.pump(const Duration(milliseconds: 800));

      // Likes count incremented
      expect(find.text('1421'), findsOneWidget);
    });
  });
}
