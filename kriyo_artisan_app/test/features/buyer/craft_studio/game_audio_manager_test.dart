import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/models/craft_studio_models.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/services/craft_game_audio_service.dart';
import 'package:kriyo_artisan_app/features/buyer/craft_studio/services/game_audio_route_observer.dart';

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

  setUp(() async {
    await GameAudioManager.instance.stopAllAudio();
  });

  tearDown(() async {
    await GameAudioManager.instance.stopAllAudio();
  });

  group('GameAudioManager Core Lifecycle & Architecture Tests', () {
    test('Singleton identity and CraftGameAudioService backward compatibility', () {
      final manager1 = GameAudioManager.instance;
      final manager2 = GameAudioManager();
      final craftAudioService = CraftGameAudioService();

      expect(identical(manager1, manager2), isTrue);
      expect(identical(manager1, craftAudioService), isTrue);
      expect(GameAudioManager.craftBgmMap.length, equals(6));
      expect(CraftGameAudioService.craftBgmMap.length, equals(6));
    });

    test('All 6 craft games have distinct unique BGM tracks and resolve aliases', () {
      // Canonical IDs
      expect(GameAudioManager.resolveGameMusicAsset('handloom'), contains('Harry Potter'));
      expect(GameAudioManager.resolveGameMusicAsset('pottery'), contains('Cornfield_Chase'));
      expect(GameAudioManager.resolveGameMusicAsset('painting'), contains('Ez Ez Bgm'));
      expect(GameAudioManager.resolveGameMusicAsset('woodcraft'), contains('Believer'));
      expect(GameAudioManager.resolveGameMusicAsset('metalcraft'), contains('Game Of Thrones'));
      expect(GameAudioManager.resolveGameMusicAsset('basketry'), contains('Rasputin'));

      // Descriptive Aliases from requirements
      expect(GameAudioManager.resolveGameMusicAsset('walnut_wood_carving'), contains('Believer'));
      expect(GameAudioManager.resolveGameMusicAsset('walnut-carving'), contains('Believer'));
      expect(GameAudioManager.resolveGameMusicAsset('dhokra_metalcraft'), contains('Game Of Thrones'));
      expect(GameAudioManager.resolveGameMusicAsset('dhokra'), contains('Game Of Thrones'));
      expect(GameAudioManager.resolveGameMusicAsset('cane_weaving'), contains('Rasputin'));
      expect(GameAudioManager.resolveGameMusicAsset('golden_grass'), contains('Rasputin'));
      expect(GameAudioManager.resolveGameMusicAsset('terracotta_pottery'), contains('Cornfield_Chase'));
      expect(GameAudioManager.resolveGameMusicAsset('folk_painting'), contains('Ez Ez Bgm'));
    });

    test('Entering Game A marks it as active audio owner', () async {
      final manager = GameAudioManager.instance;
      await manager.enterGame('walnut_wood_carving');

      expect(manager.currentGameId, equals('woodcraft'));
      expect(manager.currentMusic, contains('Believer'));
      expect(manager.currentCraftBgm, equals('woodcraft'));
    });

    test('Exiting Game A stops BGM completely and clears active state', () async {
      final manager = GameAudioManager.instance;
      await manager.enterGame('dhokra_metalcraft');
      expect(manager.currentGameId, equals('metalcraft'));

      await manager.exitGame();
      expect(manager.currentGameId, isNull);
      expect(manager.currentMusic, isNull);
    });

    test('Exiting with specific gameId does not interfere with a different active game', () async {
      final manager = GameAudioManager.instance;
      await manager.enterGame('cane_weaving');
      expect(manager.currentGameId, equals('basketry'));

      // Attempt to stop another game
      await manager.exitGame(gameId: 'handloom');
      expect(manager.currentGameId, equals('basketry'));

      // Stop the matching game
      await manager.exitGame(gameId: 'cane_weaving');
      expect(manager.currentGameId, isNull);
    });

    test('Game Switching: Entering Game B stops Game A audio and starts Game B', () async {
      final manager = GameAudioManager.instance;

      // Start Game A
      await manager.enterGame('walnut_wood_carving');
      expect(manager.currentGameId, equals('woodcraft'));
      expect(manager.currentMusic, contains('Believer'));

      // Switch to Game B
      await manager.switchGame('dhokra_metalcraft');
      expect(manager.currentGameId, equals('metalcraft'));
      expect(manager.currentMusic, contains('Game Of Thrones'));

      // Switch to Game C
      await manager.switchGame('cane_weaving');
      expect(manager.currentGameId, equals('basketry'));
      expect(manager.currentMusic, contains('Rasputin'));
    });

    test('Reopen Test: Opening Game A again does not create duplicate players', () async {
      final manager = GameAudioManager.instance;

      await manager.playGameMusic('handloom');
      expect(manager.currentGameId, equals('handloom'));
      final track1 = manager.currentMusic;

      // Call again for the same game
      await manager.playGameMusic('handloom');
      expect(manager.currentGameId, equals('handloom'));
      expect(manager.currentMusic, equals(track1));
    });

    test('Rapid Navigation Test: Rapid switching and exiting has clean final state', () async {
      final manager = GameAudioManager.instance;

      await manager.enterGame('woodcraft');
      await manager.exitGame();
      await manager.enterGame('metalcraft');
      await manager.exitGame();
      await manager.enterGame('basketry');
      await manager.exitGame();

      expect(manager.currentGameId, isNull);
      expect(manager.currentMusic, isNull);
    });

    test('Volume & Settings Control respects music/sfx enable flags and volume sliders', () {
      final manager = GameAudioManager.instance;

      manager.setMusicVolume(0.4);
      expect(manager.musicVolume, closeTo(0.4, 0.01));

      manager.setSfxVolume(0.6);
      expect(manager.sfxVolume, closeTo(0.6, 0.01));

      manager.setMusicEnabled(false);
      expect(manager.isMusicEnabled, isFalse);

      manager.setMusicEnabled(true);
      expect(manager.isMusicEnabled, isTrue);

      manager.toggleMute();
      expect(manager.isMuted, isTrue);

      manager.toggleMute();
      expect(manager.isMuted, isFalse);
    });

    test('App Lifecycle Handling pauses BGM when app is paused/inactive and restores on resume', () async {
      final manager = GameAudioManager.instance;
      await manager.enterGame('pottery');
      expect(manager.currentGameId, equals('pottery'));

      // Simulate app moved to background / screen lock
      manager.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Simulate app resumed
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(manager.currentGameId, equals('pottery'));

      // Simulate app detached
      manager.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(manager.currentGameId, isNull);
    });
  });

  group('Route Safety & GameAudioRouteObserver Tests', () {
    test('GameAudioRouteObserver identifies craft game routes vs external routes', () {
      final workshopRoute = MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.customerCraftStudioWorkshop),
        builder: (_) => const SizedBox(),
      );
      final materialsRoute = MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.customerCraftStudioMaterials),
        builder: (_) => const SizedBox(),
      );
      final completionRoute = MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.customerCraftStudioComplete),
        builder: (_) => const SizedBox(),
      );
      final exploreRoute = MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.customerExplore),
        builder: (_) => const SizedBox(),
      );
      final homeRoute = MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.customerHome),
        builder: (_) => const SizedBox(),
      );

      expect(GameAudioRouteObserver.isCraftGameRoute(workshopRoute), isTrue);
      expect(GameAudioRouteObserver.isCraftGameRoute(materialsRoute), isTrue);
      expect(GameAudioRouteObserver.isCraftGameRoute(completionRoute), isTrue);
      expect(GameAudioRouteObserver.isCraftGameRoute(exploreRoute), isFalse);
      expect(GameAudioRouteObserver.isCraftGameRoute(homeRoute), isFalse);
    });

    test('Navigating to non-game route automatically stops game audio', () async {
      final manager = GameAudioManager.instance;
      final observer = GameAudioRouteObserver();

      await manager.enterGame('walnut_wood_carving');
      expect(manager.currentGameId, equals('woodcraft'));

      // Simulate user navigated to Explore
      final exploreRoute = MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.customerExplore),
        builder: (_) => const SizedBox(),
      );
      observer.didPush(exploreRoute, null);

      expect(manager.currentGameId, isNull);
      expect(manager.currentMusic, isNull);
    });
  });
}
