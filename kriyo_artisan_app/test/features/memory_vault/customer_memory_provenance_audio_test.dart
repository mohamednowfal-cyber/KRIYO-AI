import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/core/media/audio_player_service.dart';
import 'package:kriyo_artisan_app/features/artisan/memory_vault/memory_detail_screen.dart';
import 'package:kriyo_artisan_app/features/memory_vault/data/models/memory_model.dart';
import 'package:kriyo_artisan_app/features/memory_vault/services/memory_audio_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('MemoryAudioResolver Unit Tests', () {
    test('Resolves bundled asset audio for Grandmother\'s Weaving Story', () async {
      final memory = MemoryModel(
        id: '1',
        artisanId: 'artisan_1',
        title: "Grandmother's Weaving Story",
        mediaType: 'Voice Recording',
        duration: '02:14',
        mediaUrl: '',
        filePath: 'assets/audio/grandmothers_weaving_story.m4a',
        createdAt: DateTime.now(),
      );

      final result = await MemoryAudioResolver.resolveAudioSource(memory);
      expect(result.isAvailable, isTrue);
      expect(result.type, equals(AudioSourceType.asset));
      expect(result.path, equals('assets/audio/grandmothers_weaving_story.m4a'));
      expect(result.errorMessage, isNull);
    });

    test('Resolves bundled asset audio when specified in mediaUrl', () async {
      final memory = MemoryModel(
        id: '2',
        artisanId: 'artisan_1',
        title: 'Song of the Shuttle Loom',
        mediaType: 'Voice Recording',
        duration: '01:45',
        mediaUrl: 'assets/audio/song_of_the_shuttle_loom.m4a',
        createdAt: DateTime.now(),
      );

      final result = await MemoryAudioResolver.resolveAudioSource(memory);
      expect(result.isAvailable, isTrue);
      expect(result.type, equals(AudioSourceType.asset));
      expect(result.path, equals('assets/audio/song_of_the_shuttle_loom.m4a'));
    });

    test('Returns unavailable for missing file with helpful message', () async {
      final memory = MemoryModel(
        id: '99',
        artisanId: 'artisan_1',
        title: 'Missing Tape',
        mediaType: 'Voice Recording',
        mediaUrl: '',
        filePath: '/non_existent_path/recording_12345.m4a',
        createdAt: DateTime.now(),
      );

      final result = await MemoryAudioResolver.resolveAudioSource(memory);
      expect(result.isAvailable, isFalse);
      expect(result.errorMessage, contains('Recording is temporarily unavailable'));
    });

    test('Handles remote URL sources', () async {
      final memory = MemoryModel(
        id: '3',
        artisanId: 'artisan_1',
        title: 'Remote Guild Archive',
        mediaType: 'Voice Recording',
        mediaUrl: 'https://archive.kriyo.art/audio/master_narayanan.m4a',
        createdAt: DateTime.now(),
      );

      final result = await MemoryAudioResolver.resolveAudioSource(memory);
      // Validates URL format parsing
      expect(result.type, equals(AudioSourceType.remoteUrl));
      expect(result.path, equals('https://archive.kriyo.art/audio/master_narayanan.m4a'));
    });

    test('Returns unavailable when memory has neither filePath nor mediaUrl', () async {
      final memory = MemoryModel(
        id: '4',
        artisanId: 'artisan_1',
        title: 'Empty Audio',
        mediaType: 'Voice Recording',
        mediaUrl: '',
        createdAt: DateTime.now(),
      );

      final result = await MemoryAudioResolver.resolveAudioSource(memory);
      expect(result.isAvailable, isFalse);
      expect(result.errorMessage, contains('Unable to locate this heritage recording'));
    });
  });

  group('KriyoAudioPlayerState and AudioPlayerService Tests', () {
    test('KriyoAudioPlayerState includes all required states', () {
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.idle));
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.loading));
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.ready));
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.playing));
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.paused));
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.completed));
      expect(KriyoAudioPlayerState.values, contains(KriyoAudioPlayerState.error));
    });

    test('AudioPlayerService initializes in idle state', () {
      final service = AudioPlayerService();
      expect(service.state, equals(KriyoAudioPlayerState.idle));
      expect(service.position, equals(Duration.zero));
      service.dispose();
    });
  });

  group('Memory Provenance Screen Audio UI Tests', () {
    Widget buildDetailApp({required String memoryId}) {
      final router = GoRouter(
        initialLocation: '/memory-detail/$memoryId',
        routes: [
          GoRoute(
            path: '/memory-detail/:id',
            builder: (context, state) =>
                MemoryDetailScreen(id: state.pathParameters['id'] ?? '1'),
          ),
        ],
      );

      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
    }

    testWidgets('Renders Grandmother\'s Weaving Story audio controls & metadata',
        (tester) async {
      await tester.pumpWidget(buildDetailApp(memoryId: '1'));
      await tester.pumpAndSettle();

      // Verify Header and Title
      expect(find.text('Memory Provenance'), findsOneWidget);
      expect(find.text("Grandmother's Weaving Story"), findsWidgets);

      // Verify Voice metadata duration
      expect(find.textContaining('Voice Recording • Duration 02:14 • Audio M4A'), findsOneWidget);

      // Verify Initial Play Button state
      expect(find.text('Play Archive Audio'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

      // Verify Progress Slider is visible
      expect(find.byType(Slider), findsOneWidget);

      // Verify Initial duration timestamps
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('02:14'), findsOneWidget);
    });

    testWidgets('Transcript language switch updates text without affecting audio screen',
        (tester) async {
      await tester.pumpWidget(buildDetailApp(memoryId: '1'));
      await tester.pumpAndSettle();

      // Default is Tamil
      expect(find.textContaining('எங்கள் பாட்டி 70 வருட பழமையான'), findsOneWidget);
      expect(find.text('Play Archive Audio'), findsOneWidget);

      // Change language to English
      final dropdown = find.byType(DropdownButton<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      // English translation appears, original audio button still intact
      expect(find.textContaining('My grandmother taught me this Korvai weaving technique'), findsOneWidget);
      expect(find.text('Play Archive Audio'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Slider is interactive and allows user seeking', (tester) async {
      await tester.pumpWidget(buildDetailApp(memoryId: '1'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider forward
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();

      // Verify slider widget exists and rendered smoothly
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
