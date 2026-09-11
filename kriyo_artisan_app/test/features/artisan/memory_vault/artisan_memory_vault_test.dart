import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/memory_vault/memory_detail_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/memory_vault/memory_vault_screen.dart';
import 'package:kriyo_artisan_app/features/memory_vault/data/models/memory_model.dart';
import 'package:kriyo_artisan_app/features/memory_vault/presentation/providers/memory_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildVaultApp({ProviderContainer? container}) {
    final router = GoRouter(
      initialLocation: '/memory-vault',
      routes: [
        GoRoute(
          path: '/memory-vault',
          builder: (context, state) => const MemoryVaultScreen(),
        ),
        GoRoute(
          path: '/memory-detail/:id',
          builder: (context, state) =>
              MemoryDetailScreen(id: state.pathParameters['id'] ?? '1'),
        ),
        GoRoute(
          path: '/crafts/add',
          builder: (context, state) => const Scaffold(body: Text('Add Memory Screen')),
        ),
        GoRoute(
          path: '/heritage-permissions',
          builder: (context, state) =>
              const Scaffold(body: Text('Consent Settings Screen')),
        ),
      ],
    );

    final app = MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );

    if (container != null) {
      return UncontrolledProviderScope(container: container, child: app);
    }
    return ProviderScope(child: app);
  }

  group('Artisan Heritage Memory Vault Tests', () {
    testWidgets('Displays exactly FIVE filter categories and Demonstration is absent',
        (tester) async {
      await tester.pumpWidget(buildVaultApp());
      await tester.pumpAndSettle();

      // Verify categories
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);

      // Verify Demonstration is not in the list
      expect(find.text('Demonstration'), findsNothing);
      expect(find.text('Craft Demonstrations'), findsNothing);

      // Verify Header & Consent Settings
      expect(find.text('Heritage Memory Vault'), findsOneWidget);
      expect(find.text('Consent Settings'), findsOneWidget);
    });

    testWidgets('Filtering by category displays matching memories', (tester) async {
      await tester.pumpWidget(buildVaultApp());
      await tester.pumpAndSettle();

      // Initial shows all
      expect(find.text("Grandmother's Weaving Story"), findsOneWidget);
      expect(find.text('Traditional Border Pattern Archive'), findsOneWidget);
      expect(find.text('How We Prepare Natural Dye Vat'), findsOneWidget);

      // Tap 'Voice' filter
      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();

      // Only voice memories visible
      expect(find.text("Grandmother's Weaving Story"), findsOneWidget);
      expect(find.text('Song of the Shuttle Loom'), findsOneWidget);
      expect(find.text('Traditional Border Pattern Archive'), findsNothing);
      expect(find.text('How We Prepare Natural Dye Vat'), findsNothing);

      // Tap 'Photos' filter
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();

      expect(find.text('Traditional Border Pattern Archive'), findsOneWidget);
      expect(find.text("Grandmother's Weaving Story"), findsNothing);
    });

    testWidgets('Tapping a memory card navigates to Memory Provenance detail screen',
        (tester) async {
      await tester.pumpWidget(buildVaultApp());
      await tester.pumpAndSettle();

      // Tap Grandmother's Weaving Story
      await tester.tap(find.text("Grandmother's Weaving Story"));
      await tester.pumpAndSettle();

      // Should be on Memory Provenance screen
      expect(find.text('Memory Provenance'), findsOneWidget);
      expect(find.text('Play Archive Audio'), findsOneWidget);
      expect(find.text('Transcript Language'), findsOneWidget);
      expect(find.text('Provenance & Sovereignty Record'), findsOneWidget);
    });

    testWidgets('Memory Provenance displays Audio player and real transcription in Tamil/English/Hindi',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildVaultApp(container: container));
      await tester.pumpAndSettle();

      // Navigate to Grandmother's Weaving Story
      await tester.tap(find.text("Grandmother's Weaving Story"));
      await tester.pumpAndSettle();

      // Verify Voice metadata
      expect(find.text("Grandmother's Weaving Story"), findsOneWidget);
      expect(find.textContaining('Voice Recording'), findsOneWidget);

      // Default language is Tamil -> shows Tamil transcript & English translation preview
      expect(find.textContaining('எங்கள் பாட்டி 70 வருட பழமையான தேக்கு மர தறியில்'), findsOneWidget);
      expect(find.textContaining('My grandmother taught me this Korvai weaving technique'), findsOneWidget);

      // Provenance record details
      expect(find.text('Lakshmi Narayanan (Master Weaver)'), findsOneWidget);
      expect(find.text('Oral Technique History & Family Lineage'), findsOneWidget);
      expect(find.text('Walajabad Pit Loom Weavers Guild'), findsOneWidget);
      expect(find.text('✓ Community Guild Verified'), findsOneWidget);

      // Audio Player buttons & seeking bar exist
      expect(find.text('Play Archive Audio'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Tap Play Archive Audio
      await tester.tap(find.text('Play Archive Audio'));
      await tester.pump();

      // Tap back button returns to Memory Vault list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Heritage Memory Vault'), findsOneWidget);
    });

    testWidgets('Switching transcript language updates displayed translation',
        (tester) async {
      await tester.pumpWidget(buildVaultApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text("Grandmother's Weaving Story"));
      await tester.pumpAndSettle();

      // Tap Transcript Language Dropdown
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select Hindi
      await tester.tap(find.text('Hindi').last);
      await tester.pumpAndSettle();

      // Should display Hindi text and AI Translation badge
      expect(find.textContaining('मेरी दादी ने मुझे वालाजाबाद में'), findsOneWidget);
      expect(find.text('Original Transcription (Hindi)'), findsNothing);
      expect(find.text('Hindi Translation'), findsOneWidget);

      // Select English
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('My grandmother taught me this Korvai weaving technique'), findsOneWidget);
      expect(find.text('English Translation'), findsOneWidget);
    });

    testWidgets('Newly saved memory appears in the Vault list immediately',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildVaultApp(container: container));
      await tester.pumpAndSettle();

      // Save a new memory
      final newMem = MemoryModel(
        id: 'new_unique_101',
        title: 'Master Loom Bamboo Reed Tuning',
        mediaType: 'Voice',
        mediaUrl: 'assets/audio/test.m4a',
        duration: '03:10',
        createdAt: DateTime.now(),
        permissionState: 'Educational Use',
        transcription: 'Tuning bamboo reeds with organic wax.',
        translations: {
          'en': 'Tuning bamboo reeds with organic wax.',
          'ta': 'மூங்கில் நாணலை இயற்கை மெழுகால் சீரமைத்தல்.',
          'hi': 'जैविक मोम के साथ बांस के नरकट को ट्यून करना।',
        },
      );

      await container.read(memoryProvider.notifier).saveMemory(newMem);
      await tester.pumpAndSettle();

      // The new memory should now be visible at top of the vault list
      expect(find.text('Master Loom Bamboo Reed Tuning'), findsOneWidget);
      expect(find.textContaining('03:10'), findsOneWidget);
      expect(find.text('Educational Use'), findsOneWidget);
    });
  });
}
