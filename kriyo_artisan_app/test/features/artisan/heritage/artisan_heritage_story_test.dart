import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/features/artisan/craft/craft_story_view_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/heritage/add_heritage_memory_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/heritage/heritage_home_screen.dart';

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
  });

  GoRouter createTestRouter({String initialLocation = AppRoutes.heritage}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.heritage,
          builder: (context, state) => const HeritageHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.addHeritage,
          builder: (context, state) => const AddHeritageMemoryScreen(),
        ),
        GoRoute(
          path: '/craft-story-view',
          builder: (context, state) => const CraftStoryViewScreen(),
        ),
      ],
    );
  }

  Widget buildApp(GoRouter router) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
  }

  group('Part 1 — My Heritage Screen Fixes', () {
    testWidgets('Bottom button has single Add icon and exact label "Add Heritage Memory"',
        (tester) async {
      final router = createTestRouter(initialLocation: AppRoutes.heritage);
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Find bottom button
      final bottomButtonFinder = find.widgetWithText(
        ElevatedButton,
        'Add Heritage Memory',
      );
      expect(bottomButtonFinder, findsOneWidget);

      // Verify no duplicate text like "+  + Add Heritage Memory"
      expect(find.textContaining('++'), findsNothing);
      expect(find.text('+  + Add Heritage Memory'), findsNothing);

      // Verify button has single Icon(Icons.add)
      final iconFinder = find.descendant(
        of: bottomButtonFinder,
        matching: find.byIcon(Icons.add),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Tapping bottom button navigates to Preserve Heritage Memory and back',
        (tester) async {
      final router = createTestRouter(initialLocation: AppRoutes.heritage);
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Tap "Add Heritage Memory"
      final addBtn = find.widgetWithText(ElevatedButton, 'Add Heritage Memory');
      await tester.ensureVisible(addBtn);
      await tester.pumpAndSettle();
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Should be on Preserve Heritage Memory screen
      expect(find.text('Preserve Heritage Memory'), findsOneWidget);
      expect(find.text('Recording Oral Memory'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on My Heritage screen
      expect(find.text('My Heritage'), findsOneWidget);
      expect(find.text('Documented Dimensions'), findsOneWidget);
    });

    testWidgets('Tapping Craft Story tile navigates directly to Artisan Oral Heritage Story',
        (tester) async {
      final router = createTestRouter(initialLocation: AppRoutes.heritage);
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Scroll and tap "Craft Story"
      final craftStoryTile = find.text('Craft Story');
      expect(craftStoryTile, findsOneWidget);
      await tester.ensureVisible(craftStoryTile);
      await tester.pumpAndSettle();
      await tester.tap(craftStoryTile);
      await tester.pumpAndSettle();

      // Should be on Artisan Oral Heritage Story screen
      expect(find.text('Artisan Oral Heritage Story'), findsOneWidget);
      expect(find.text('Original Spoken Tamil (வாய்மொழி வரலாறு)'), findsOneWidget);
    });
  });

  group('Part 2 — Artisan Oral Heritage Story & Audio Playback', () {
    testWidgets('Zero overflow across multiple viewports (320px, 360px, 375px, 412px)',
        (tester) async {
      const viewports = [
        Size(320, 640),
        Size(360, 640),
        Size(375, 812),
        Size(412, 915),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final router = createTestRouter(initialLocation: '/craft-story-view');
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        // Check for any FlutterError regarding RenderFlex overflow
        expect(tester.takeException(), isNull,
            reason: 'Screen must not throw overflow exception at ${size.width}x${size.height}');

        // Verify key headers are visible
        expect(find.text('Artisan Oral Heritage Story'), findsOneWidget);
        expect(find.text('Original Spoken Tamil (வாய்மொழி வரலாறு)'), findsOneWidget);
        expect(find.text('AI Verified English Translation'), findsOneWidget);
        expect(find.text('Cultural & Generational Context'), findsOneWidget);
        expect(find.text('Heritage Provenance & Archive Details'), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Displays all audio controls, badges, and transcripts properly',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;

      final router = createTestRouter(initialLocation: '/craft-story-view');
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Audio card controls
      expect(find.byKey(const Key('rewind_10_button')), findsOneWidget);
      expect(find.byKey(const Key('play_pause_button')), findsOneWidget);
      expect(find.byKey(const Key('forward_10_button')), findsOneWidget);
      expect(find.byKey(const Key('audio_progress_slider')), findsOneWidget);
      expect(find.byKey(const Key('audio_current_time')), findsOneWidget);
      expect(find.byKey(const Key('audio_total_duration')), findsOneWidget);

      // Track switcher
      expect(find.byKey(const Key('track_original_tamil')), findsOneWidget);
      expect(find.byKey(const Key('track_ai_english')), findsOneWidget);

      // Badges
      expect(find.text('ARTISAN SPOKEN'), findsOneWidget);
      expect(find.text('AI VERIFIED'), findsOneWidget);
      expect(find.text('AI HERITAGE CONTEXT'), findsOneWidget);

      // Provenance info
      expect(find.text('KRIYO Mobile Oral Vault (Lossless 48kHz)'), findsOneWidget);
      expect(find.text('Lakshmi Ammal'), findsOneWidget);
      expect(find.text('Verified by Kanchipuram Weavers Guild & KRIYO AI Oral Archivist'),
          findsOneWidget);

      // Test Track Switching
      await tester.tap(find.byKey(const Key('track_ai_english')));
      await tester.pumpAndSettle();

      // Play button tap test
      await tester.tap(find.byKey(const Key('play_pause_button')));
      await tester.pump();

      // Rewind / forward tap test
      await tester.tap(find.byKey(const Key('rewind_10_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('forward_10_button')));
      await tester.pump();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
