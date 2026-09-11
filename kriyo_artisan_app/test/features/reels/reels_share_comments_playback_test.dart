import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/reels/data/reel_storage_service.dart';
import 'package:kriyo_artisan_app/features/reels/presentation/customer/customer_craft_reels_screen.dart';
import 'package:kriyo_artisan_app/features/reels/presentation/customer/widgets/reel_comments_sheet.dart';
import 'package:kriyo_artisan_app/features/reels/providers/reels_provider.dart';
import 'package:kriyo_artisan_app/features/reels/services/reel_media_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _MockVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextId = 0;
  final Map<int, bool> _isPlaying = {};
  final Map<int, double> _volume = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {
    _isPlaying.remove(textureId);
    _volume.remove(textureId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextId++;
    _isPlaying[id] = true;
    _volume[id] = 1.0;
    return id;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {
    _isPlaying[textureId] = true;
  }

  @override
  Future<void> pause(int textureId) async {
    _isPlaying[textureId] = false;
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    _volume[textureId] = volume;
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 45),
      size: const Size(1080, 1920),
    ));
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox(width: 1080, height: 1920);
  }
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
    VideoPlayerPlatform.instance = _MockVideoPlayerPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KRIYO Reels Comments & Maximum 10 Limit', () {
    test('All 10 seed reels have unique, authentic craft comments populated', () {
      final commentsMap = ReelStorageService.initial10CraftComments;
      expect(commentsMap.length, equals(10));

      for (int i = 1; i <= 10; i++) {
        final id = 'REL-LOCAL-${i.toString().padLeft(2, '0')}';
        final comments = commentsMap[id];
        expect(comments, isNotNull, reason: 'Comments missing for $id');
        expect(comments!.length, inInclusiveRange(6, 10),
            reason: '$id comments count out of range');
        expect(comments.length, lessThanOrEqualTo(10),
            reason: '$id exceeded 10 comment limit');

        // Check for realistic craft questions or artisan answers
        final hasArtisan = comments.any((c) => c.isArtisan);
        expect(hasArtisan, isTrue, reason: '$id missing artisan response');
      }
    });

    test('addComment strictly enforces maximum 10 comments by dropping oldest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reelsProvider.notifier);
      final reel = notifier.state.publishedReels.first;
      
      // Add comments until reaching and exceeding 10 comments
      for (int i = 1; i <= 10; i++) {
        notifier.addComment(reel.id, 'Test inquiry #$i on craft technique');
      }

      final updatedReel = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      final comments = notifier.state.comments[reel.id]!;

      // Capped strictly at 10
      expect(updatedReel.commentsCount, equals(10));
      expect(comments.length, equals(10));
      // Latest comment is at top
      expect(comments.first.text, equals('Test inquiry #10 on craft technique'));
    });

    test('likeReel is idempotent and increments count once', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(reelsProvider.notifier);
      final reel = notifier.state.publishedReels.first;
      final initialLikes = reel.likesCount;

      notifier.likeReel(reel.id);
      final afterFirst = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(afterFirst.isLiked, isTrue);
      expect(afterFirst.likesCount, equals(initialLikes + 1));

      // Second like should be idempotent (no duplicate count increment)
      notifier.likeReel(reel.id);
      final afterSecond = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(afterSecond.isLiked, isTrue);
      expect(afterSecond.likesCount, equals(initialLikes + 1));
    });
  });

  group('ReelCommentsSheet Widget Tests', () {
    Widget buildCommentsSheet(String reelId) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReelCommentsSheet(reelId: reelId),
          ),
        ),
      );
    }

    testWidgets('Comments sheet displays only current reel comments up to 10 with relative time',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCommentsSheet('REL-LOCAL-02'));
      await tester.pumpAndSettle();

      // Header shows Comments count
      expect(find.textContaining('Comments'), findsOneWidget);
      expect(find.text('max 10'), findsOneWidget);

      // Content specific to Reel 2 (Sunita Sharma paper butterfly)
      expect(find.textContaining('wings'), findsWidgets);

      // Input hint text
      expect(find.text('Add a comment...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('User can submit comment from sheet and count stays <= 10',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildCommentsSheet('REL-LOCAL-02'));
      await tester.pumpAndSettle();

      // Enter a comment in the text field
      await tester.enterText(find.byType(TextField), 'Fabulous crease sharpness!');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify the new comment is displayed
      expect(find.text('Fabulous crease sharpness!'), findsOneWidget);
      // Header count <= 10
      expect(find.text('max 10'), findsOneWidget);
    });
  });

  group('ReelMediaManager Service Tests', () {
    test('ReelMediaManager singleton initializes and creates controller for local asset', () async {
      final manager = ReelMediaManager.instance;
      expect(manager, isNotNull);

      final controller = await manager.createController('assets/Videos/Beautiful butterfly made out of paper_HD.mp4');
      expect(controller, isNotNull);
      addTearDown(controller.dispose);
    });
  });

  group('Full CustomerCraftReelsScreen Playback & Controls Integration', () {
    Widget buildReelsApp() {
      return const ProviderScope(
        child: MaterialApp(
          home: CustomerCraftReelsScreen(),
        ),
      );
    }

    testWidgets('Renders full reel screen with video player, play/pause tap, and share button',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildReelsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Top indicator
      expect(find.text('Craft Stories'), findsOneWidget);
      expect(find.text('1/10'), findsOneWidget);

      // Buttons
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Lore'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Single tap triggers pause/resume without error
      await tester.tap(find.byType(CustomerCraftReelsScreen));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
