import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/l10n/app_localizations.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/models/craft_studio_models.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/providers/craft_studio_provider.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/screens/craft_studio_landing_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/services/craft_game_audio_service.dart';

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

  group('Craft Studio Data & Model Verification', () {
    test('All six craft experiences exist and are playable with non-empty steps', () {
      final experiences = CraftStudioData.experiences;
      expect(experiences.length, equals(6));

      for (final exp in experiences) {
        expect(exp.isPlayable, isTrue, reason: '${exp.id} must be playable');
        expect(exp.materials.isNotEmpty, isTrue, reason: '${exp.id} has materials');
        expect(exp.palettes.isNotEmpty, isTrue, reason: '${exp.id} has palettes');
        expect(exp.steps.length, greaterThanOrEqualTo(5), reason: '${exp.id} has at least 5 steps');
        expect(exp.learningTakeaways.isNotEmpty, isTrue, reason: '${exp.id} has learning takeaways');
      }
    });

    test('Audio BGM mapping has valid unique tracks for all 6 crafts', () {
      final bgmMap = CraftGameAudioService.craftBgmMap;
      expect(bgmMap.length, equals(6));

      final tracks = bgmMap.values.toSet();
      expect(tracks.length, equals(6), reason: 'Each craft must have a distinct unique BGM');

      expect(bgmMap[CraftExperienceId.handloom], contains('Harry Potter'));
      expect(bgmMap[CraftExperienceId.pottery], contains('Cornfield_Chase'));
      expect(bgmMap[CraftExperienceId.painting], contains('Ez Ez Bgm'));
      expect(bgmMap[CraftExperienceId.woodcraft], contains('Believer'));
      expect(bgmMap[CraftExperienceId.metalcraft], contains('Game Of Thrones'));
      expect(bgmMap[CraftExperienceId.basketry], contains('Rasputin'));
    });
  });

  group('CraftStudioNotifier 6 Playable Games Unit Tests', () {
    test('Initial state is unselected with empty creations', () {
      final notifier = CraftStudioNotifier();
      expect(notifier.state.currentCraft, isNull);
      expect(notifier.state.savedCreations, isEmpty);
      expect(notifier.state.isSoundEnabled, isTrue);
    });

    test('Handloom weaving workflow: shuttle swipe, beating, and pattern selection', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.handloom);

      notifier.selectHandloomPattern(HandloomPattern.diamond);
      expect(notifier.state.handloomPattern, equals(HandloomPattern.diamond));

      expect(notifier.state.wovenRows.length, equals(0));
      expect(notifier.state.needsBeating, isFalse);

      notifier.passShuttleSuccess();
      expect(notifier.state.wovenRows.length, equals(1));
      expect(notifier.state.needsBeating, isTrue);

      notifier.beatWeftReed();
      expect(notifier.state.needsBeating, isFalse);
    });

    test('Pottery workshop workflow: centering, wall pulling, deforming, and undo', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.pottery);

      expect(notifier.state.clayCentered, isFalse);
      notifier.centerClaySuccess();
      expect(notifier.state.clayCentered, isTrue);

      notifier.pullClayHeight(0.85);
      expect(notifier.state.clayHeight, equals(0.85));

      final originalSlice = notifier.state.clayProfile[2];
      notifier.deformClayProfile(2, 0.2);
      expect(notifier.state.clayProfile[2], isNot(equals(originalSlice)));
      expect(notifier.state.clayProfileHistory.isNotEmpty, isTrue);

      notifier.undoLastClayAction();
      expect(notifier.state.clayProfile[2], equals(originalSlice));
      expect(notifier.state.clayProfileHistory.isEmpty, isTrue);

      notifier.selectPotteryDecoration(PotteryDecoration.geometric);
      expect(notifier.state.potteryDecoration, equals(PotteryDecoration.geometric));

      notifier.applyWaterSmoothing();
      expect(notifier.state.hasWaterApplied, isTrue);
    });

    test('Painting workshop workflow: brush strokes, undo, redo, eraser, and free mode', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.painting);

      notifier.addPaintingStroke(const [Offset(10, 10), Offset(20, 20)], Colors.black);
      expect(notifier.state.drawnStrokes.length, equals(1));

      notifier.undoLastStroke();
      expect(notifier.state.drawnStrokes.isEmpty, isTrue);
      expect(notifier.state.undoneStrokes.length, equals(1));

      notifier.redoLastStroke();
      expect(notifier.state.drawnStrokes.length, equals(1));
      expect(notifier.state.undoneStrokes.isEmpty, isTrue);

      notifier.setEraserActive(true);
      expect(notifier.state.isEraserActive, isTrue);

      expect(notifier.state.isFreeCreateMode, isFalse);
      notifier.toggleFreeCreate();
      expect(notifier.state.isFreeCreateMode, isTrue);
    });

    test('Walnut Wood Carving workflow: tool selection, marking, chiseling, and relief depth', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.woodcraft);
      expect(notifier.state.currentCraft?.id, equals('woodcraft'));

      notifier.selectCarvingTool('u_chisel');
      expect(notifier.state.selectedCarvingTool, equals('u_chisel'));

      notifier.markCarvingZone(1);
      expect(notifier.state.carvedZoneIds.contains(1), isTrue);

      notifier.addCarvedStroke(const Offset(50, 50));
      expect(notifier.state.carvedPoints.isNotEmpty, isTrue);
      expect(notifier.state.woodShavingsCount, greaterThan(0));

      notifier.carveReliefDepth(0.3);
      expect(notifier.state.woodReliefDepth, closeTo(0.3, 0.01));

      notifier.polishWoodSurface();
      expect(notifier.state.woodReliefDepth, equals(1.0));
    });

    test('Lost-Wax Dhokra Metalcraft workflow: wax coils, motifs, mould, and casting', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.metalcraft);
      expect(notifier.state.currentCraft?.id, equals('metalcraft'));

      notifier.placeWaxCoil();
      expect(notifier.state.waxCoilCount, equals(1));

      notifier.setDhokraMotif('tribal_crown');
      expect(notifier.state.dhokraMotifType, equals('tribal_crown'));

      notifier.applyMouldSlip(0.5);
      expect(notifier.state.dhokraMouldProgress, closeTo(0.5, 0.01));

      notifier.heatFurnaceCast(0.6);
      expect(notifier.state.furnaceHeatProgress, closeTo(0.6, 0.01));

      notifier.breakCastMould();
      expect(notifier.state.isCastBroken, isTrue);
    });

    test('Golden Grass & Cane Weaving workflow: radial spokes, knot, interlace, and tension', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.basketry);
      expect(notifier.state.currentCraft?.id, equals('basketry'));

      notifier.arrangeSpokes();
      expect(notifier.state.spokesArranged, isTrue);

      notifier.interlaceCaneStrand();
      expect(notifier.state.interlacedRound, equals(1));

      notifier.tightenCaneTension(0.4);
      expect(notifier.state.caneTension, closeTo(0.4, 0.01));

      notifier.finishBasketRim();
      expect(notifier.state.rimCompleted, isTrue);
    });

    test('completeCraftCreation marks craft completed with 100% and saves creation', () {
      final notifier = CraftStudioNotifier();
      notifier.selectCraft(CraftExperienceId.woodcraft);

      final creation = notifier.completeCraftCreation();
      expect(creation.craftId, equals('woodcraft'));
      expect(notifier.state.savedCreations.length, equals(1));
      expect(notifier.state.getProgressState('woodcraft'), equals(CraftGameProgressState.completed));
      expect(notifier.state.getProgressPercent('woodcraft'), equals(100));
    });
  });

  group('CraftStudioLandingScreen Widget Tests', () {
    Widget createLandingWidget({
      Locale locale = const Locale('en'),
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
            Locale('hi'),
          ],
          home: const CraftStudioLandingScreen(),
        ),
      );
    }

    testWidgets('Renders Craft Studio header, tagline, and philosophy card', (tester) async {
      await tester.pumpWidget(createLandingWidget());
      await tester.pumpAndSettle();

      expect(find.text('CRAFT STUDIO'), findsOneWidget);
      expect(find.text('Create • Learn • Preserve'), findsOneWidget);
      expect(find.text('Create with your hands.'), findsOneWidget);
      expect(find.text('Digital Handmade Workshop'), findsOneWidget);
    });

    testWidgets('All six craft games are playable with Start Creating buttons and NO Coming Soon', (tester) async {
      await tester.pumpWidget(createLandingWidget());
      await tester.pumpAndSettle();

      // Verify zero Coming Soon badges or buttons
      expect(find.text('Coming Soon'), findsNothing);

      // Verify all games are present
      expect(find.text('Handloom Weaving'), findsOneWidget);
      expect(find.text('Terracotta Pottery'), findsOneWidget);
      expect(find.text('Traditional Folk Painting'), findsOneWidget);

      // Scroll to see remaining 3 games
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Walnut Wood Carving'), findsOneWidget);
      expect(find.text('Lost-Wax Dhokra Metalcraft'), findsOneWidget);
      expect(find.text('Golden Grass & Cane Weaving'), findsOneWidget);

      // Confirm Start Creating buttons exist and no Coming Soon anywhere
      expect(find.text('Coming Soon'), findsNothing);
      expect(find.text('Start Creating'), findsWidgets);
    });

    testWidgets('Renders localized strings properly in Tamil (ta)', (tester) async {
      await tester.pumpWidget(createLandingWidget(locale: const Locale('ta')));
      await tester.pumpAndSettle();

      expect(find.text('கைவினைப் பயிலகம்'), findsOneWidget);
      expect(find.text('உருவாக்கு • கற்றுக்கொள் • பாதுகாத்திடு'), findsOneWidget);
    });

    testWidgets('Renders localized strings properly in Hindi (hi)', (tester) async {
      await tester.pumpWidget(createLandingWidget(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('शिल्प स्टूडियो'), findsOneWidget);
      expect(find.text('सृजन • सीख • संरक्षण'), findsOneWidget);
    });
  });
}
