import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/reels/models/reel_models.dart';
import 'package:kriyo_artisan_app/features/reels/presentation/artisan/artisan_create_reel_screen.dart';
import 'package:kriyo_artisan_app/features/reels/presentation/artisan/artisan_reel_editor_screen.dart';
import 'package:kriyo_artisan_app/features/reels/providers/reels_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Artisan Craft Story Capture & Subtitles State & Models', () {
    test('ArtisanReelItem model properly tracks video source, duration, and subtitles', () {
      const seg1 = SubtitleSegment(
        start: Duration(seconds: 0),
        end: Duration(seconds: 4),
        originalText: 'பாரம்பரிய தறி ஓசை',
        translatedText: 'Traditional loom rhythm',
      );

      final item = ArtisanReelItem(
        id: 'CRAFT-STORY-101',
        artisanId: 'ART-001',
        artisanName: 'Lakshmi Devi',
        artisanRole: 'Master Weaver',
        artisanAvatar: 'https://kriyo.in/artisan.jpg',
        region: 'Kanchipuram, Tamil Nadu',
        videoUrl: '/path/to/recorded_craft_story.mp4',
        thumbnailUrl: '/path/to/thumb.jpg',
        caption: 'Traditional Korvai three-shuttle border technique.',
        craftType: 'Handloom Weaving',
        technique: 'Korvai Dual Shuttle Joining',
        createdAt: DateTime.now(),
        sourceType: CraftStorySourceType.camera,
        mediaType: CraftStoryMediaType.video,
        localMediaPath: '/path/to/recorded_craft_story.mp4',
        videoDuration: const Duration(seconds: 30),
        detectedLanguage: 'Tamil',
        selectedSubtitleLang: 'Tamil + English',
        subtitleSegments: const [seg1],
        audioTrackPath: '/path/to/voice_narration.m4a',
        audioTrackName: 'Master Artisan Narration',
        audioTrackDuration: const Duration(seconds: 45),
        originalVideoAudioPreserved: true,
      );

      expect(item.sourceType, equals(CraftStorySourceType.camera));
      expect(item.mediaType, equals(CraftStoryMediaType.video));
      expect(item.videoDuration?.inSeconds, equals(30));
      expect(item.detectedLanguage, equals('Tamil'));
      expect(item.subtitleSegments.length, equals(1));
      expect(item.subtitleSegments.first.originalText, equals('பாரம்பரிய தறி ஓசை'));
      expect(item.subtitleSegments.first.translatedText, equals('Traditional loom rhythm'));
      expect(item.audioTrackName, equals('Master Artisan Narration'));
      expect(item.originalVideoAudioPreserved, isTrue);
    });

    test('SubtitleSegment serialization and copyWith works correctly', () {
      const seg = SubtitleSegment(
        start: Duration(seconds: 2),
        end: Duration(seconds: 6),
        originalText: 'மண் சக்கரம்',
        translatedText: 'Pottery wheel centering',
      );

      final json = seg.toJson();
      expect(json['startMs'], equals(2000));
      expect(json['endMs'], equals(6000));
      expect(json['originalText'], equals('மண் சக்கரம்'));

      final restored = SubtitleSegment.fromJson(json);
      expect(restored.start, equals(const Duration(seconds: 2)));
      expect(restored.end, equals(const Duration(seconds: 6)));
      expect(restored.translatedText, equals('Pottery wheel centering'));

      final edited = restored.copyWith(originalText: 'மண் சக்கரம் சுழல்கிறது');
      expect(edited.originalText, equals('மண் சக்கரம் சுழல்கிறது'));
      expect(edited.translatedText, equals('Pottery wheel centering'));
    });

    test('ReelsNotifier preserves draft between screens and supports offline saving', () {
      final notifier = ReelsNotifier();

      final draft = ArtisanReelItem(
        id: 'DRAFT-01',
        artisanId: 'ART-001',
        artisanName: 'Lakshmi Devi',
        artisanRole: 'Master Weaver',
        artisanAvatar: 'https://kriyo.in/artisan.jpg',
        region: 'Kanchipuram, Tamil Nadu',
        videoUrl: '/local/story.mp4',
        thumbnailUrl: '/local/thumb.jpg',
        caption: 'Initial craft story draft',
        craftType: 'Handloom Weaving',
        technique: 'Korvai Dual Shuttle Joining',
        createdAt: DateTime.now(),
        localMediaPath: '/local/story.mp4',
      );

      // Save draft
      notifier.updateActiveDraft(draft);
      expect(notifier.state.activeDraft, isNotNull);
      expect(notifier.state.activeDraft?.caption, equals('Initial craft story draft'));
      expect(notifier.state.activeDraft?.isSavedOffline, isFalse);

      // Mark offline
      notifier.saveDraftOffline();
      expect(notifier.state.activeDraft?.isSavedOffline, isTrue);

      // Clear draft
      notifier.clearActiveDraft();
      expect(notifier.state.activeDraft, isNull);
    });
  });

  group('Capture Craft Story UI & Duration Tests', () {
    testWidgets('Capture screen displays 15s, 30s, 60s chips, prompt card, Gallery & Camera controls',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanCreateReelScreen(),
          ),
        ),
      );
      await tester.pump();

      // Top title and Next button
      expect(find.text('Capture Craft Story'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Duration selector chips
      expect(find.text('15s'), findsOneWidget);
      expect(find.text('30s'), findsOneWidget);
      expect(find.text('60s'), findsOneWidget);

      // Prompt hint card
      expect(find.textContaining('Prompt: Show the delicate interlocking of threads'), findsOneWidget);

      // Bottom controls
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Switch Camera'), findsOneWidget);
      expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);

      // Test switching duration chips
      await tester.tap(find.text('15s'));
      await tester.pump();

      await tester.tap(find.text('60s'));
      await tester.pump();
    });
  });

  group('Edit Story & Subtitles UI & Editing Tests', () {
    testWidgets('Edit screen renders video preview, AI subtitles, bilingual chips, and audio track section',
        (tester) async {
      final container = ProviderContainer();
      final sampleDraft = ArtisanReelItem(
        id: 'DRAFT-TEST',
        artisanId: 'ART-001',
        artisanName: 'Lakshmi Devi',
        artisanRole: 'Master Weaver',
        artisanAvatar: 'https://kriyo.in/artisan.jpg',
        region: 'Kanchipuram, Tamil Nadu',
        videoUrl: 'https://kriyo.in/demo.mp4',
        thumbnailUrl: 'https://kriyo.in/demo.jpg',
        caption: 'Mastering the Korvai dual shuttle temple border joining.',
        craftType: 'Handloom Weaving',
        technique: 'Korvai Dual Shuttle Joining',
        createdAt: DateTime.now(),
        detectedLanguage: 'Tamil',
        selectedSubtitleLang: 'Tamil + English',
      );

      container.read(reelsProvider.notifier).updateActiveDraft(sampleDraft);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ArtisanReelEditorScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify Header
      expect(find.text('Edit Story & Subtitles'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Verify Caption
      expect(find.text('Craft Story Caption'), findsOneWidget);
      expect(
        find.text('Mastering the Korvai dual shuttle temple border joining.'),
        findsOneWidget,
      );

      // Verify AI Subtitles & Cultural Translation section
      expect(find.text('AI Subtitles & Cultural Translation'), findsOneWidget);
      expect(find.text('Tamil + English'), findsOneWidget);
      expect(find.text('Hindi + English'), findsOneWidget);
      expect(find.text('English Only'), findsOneWidget);
      expect(find.text('Detected Language: '), findsOneWidget);

      // Verify Audio Track section
      expect(find.text('Audio Track'), findsOneWidget);
      expect(find.textContaining('Add Audio Track'), findsOneWidget);

      // Verify Next CTA
      expect(find.text('Next: Link Product & Masterclass'), findsOneWidget);
    });

    testWidgets('Editing subtitle text updates content and displays Save Subtitle Edit action',
        (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ArtisanReelEditorScreen(),
          ),
        ),
      );
      await tester.pump();

      // Find original language subtitle field and enter new text
      final subtitleFields = find.byType(TextField);
      expect(subtitleFields, findsWidgets);

      // Type into the original subtitle field
      await tester.enterText(subtitleFields.at(1), 'புதிய கைவினை உரை திருத்தம்');
      await tester.pump();

      // Save Subtitle Edit button appears
      expect(find.text('Save Subtitle Edit'), findsOneWidget);

      // Scroll into view and tap save
      await tester.scrollUntilVisible(
        find.text('Save Subtitle Edit'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save Subtitle Edit'));
      await tester.pump();

      // Button disappears after saving
      expect(find.text('Save Subtitle Edit'), findsNothing);
    });
  });
}
