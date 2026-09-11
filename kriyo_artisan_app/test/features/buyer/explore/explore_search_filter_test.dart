import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/core/localization/locale_provider.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/data/explore_repository.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/explore_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/models/explore_filter_state.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/widgets/explore_filter_bottom_sheet.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/widgets/explore_search_bar.dart';

void main() {
  group('ExploreRepository - Authoritative Multi-State Catalog & Search Logic', () {
    const repository = LocalExploreRepository();

    test('Initial repository returns all 524 authoritative craft products', () {
      final all = repository.getAllProducts();
      expect(all.length, 524);
    });

    test('Catalog contains products across all 11 authoritative states', () {
      final allStates = repository.getAllStates();
      expect(allStates.length, 11);
      final allProducts = repository.getAllProducts();

      for (final state in allStates) {
        final stateProducts = allProducts.where((p) => p.state == state).toList();
        expect(
          stateProducts.isNotEmpty,
          true,
          reason: 'Expected products for state: $state',
        );
      }
    });

    test('Dynamic district extraction returns districts for state', () {
      final tnDistricts = repository.getDistrictsForState('Tamil Nadu');
      expect(tnDistricts.isNotEmpty, true);
      expect(tnDistricts.contains('Kanchipuram'), true);

      final rjDistricts = repository.getDistrictsForState('Rajasthan');
      expect(rjDistricts.isNotEmpty, true);
      expect(rjDistricts.contains('Jaipur'), true);
    });

    test('Search "saree" returns matching saree and silk crafts via semantic aliases', () {
      final results = repository.searchAndFilter(
        query: 'saree',
        filter: const ExploreFilterState(),
      );
      expect(results.isNotEmpty, true);
      for (final p in results) {
        final text = [
          p.title,
          p.craftType,
          p.description,
          p.craftStory,
          p.notes ?? '',
          ...p.techniques,
          ...p.materials,
          ...p.tags,
        ].join(' ').toLowerCase();
        expect(text.contains('saree') || text.contains('sari') || text.contains('drape'), true);
      }
    });

    test('Search "pottery" returns pottery and terracotta related crafts', () {
      final results = repository.searchAndFilter(
        query: 'pottery',
        filter: const ExploreFilterState(),
      );
      expect(results.isNotEmpty, true);
      expect(
        results.any((p) =>
            p.title.toLowerCase().contains('terracotta') ||
            p.title.toLowerCase().contains('pottery') ||
            p.craftType.toLowerCase().contains('pottery') ||
            p.craftType.toLowerCase().contains('clay')),
        true,
      );
    });

    test('Search "wood" returns woodcraft products', () {
      final results = repository.searchAndFilter(
        query: 'wood',
        filter: const ExploreFilterState(),
      );
      expect(results.isNotEmpty, true);
      expect(
        results.any((p) =>
            p.title.toLowerCase().contains('wood') ||
            p.craftType.toLowerCase().contains('wood')),
        true,
      );
    });

    test('Search "basket" returns basketry or natural fiber crafts', () {
      final results = repository.searchAndFilter(
        query: 'basket',
        filter: const ExploreFilterState(),
      );
      expect(results.isNotEmpty, true);
      expect(
        results.any((p) =>
            p.title.toLowerCase().contains('basket') ||
            p.craftType.toLowerCase().contains('basket') ||
            p.description.toLowerCase().contains('basket') ||
            p.craftType.toLowerCase().contains('cane') ||
            p.craftType.toLowerCase().contains('sabai')),
        true,
      );
    });

    test('Search region "Kanchipuram" returns matching products', () {
      final results = repository.searchAndFilter(
        query: 'Kanchipuram',
        filter: const ExploreFilterState(),
      );
      expect(results.isNotEmpty, true);
      expect(results.every((p) => p.region.contains('Kanchipuram') || (p.district?.contains('Kanchipuram') ?? false)), true);
    });

    test('Filter by Category: Handloom & Textiles', () {
      final results = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(selectedCategory: 'Handloom & Textiles'),
      );
      expect(results.isNotEmpty, true);
      for (final p in results) {
        final text = '${p.craftType} ${p.title}'.toLowerCase();
        expect(
          text.contains('loom') ||
              text.contains('weaving') ||
              text.contains('textile') ||
              text.contains('silk') ||
              text.contains('cotton') ||
              text.contains('saree'),
          true,
        );
      }
    });

    test('Filter by Region: Tamil Nadu isolates strictly to Tamil Nadu products', () {
      final results = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(selectedRegion: 'Tamil Nadu'),
      );
      expect(results.isNotEmpty, true);
      for (final p in results) {
        expect(p.state == 'Tamil Nadu' || p.region.contains('Tamil Nadu'), true);
      }
    });

    test('Filter by District: Kanchipuram within Tamil Nadu', () {
      final results = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(
          selectedRegion: 'Tamil Nadu',
          selectedDistrict: 'Kanchipuram',
        ),
      );
      expect(results.isNotEmpty, true);
      for (final p in results) {
        expect(p.district?.toLowerCase().contains('kanchipuram') ?? false, true);
      }
    });

    test('Filter by GI Tag only', () {
      final results = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(isGiOnly: true),
      );
      expect(results.isNotEmpty, true);
      for (final p in results) {
        expect(p.isGiTagged, true);
      }
    });

    test('Filter by Famous Heritage vs Lesser-Known', () {
      final famous = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(famousFilter: FamousFilterOption.famous),
      );
      expect(famous.isNotEmpty, true);
      for (final p in famous) {
        expect(p.famousOrLesser?.toLowerCase(), 'famous');
      }

      final lesser = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(famousFilter: FamousFilterOption.lesserKnown),
      );
      expect(lesser.isNotEmpty, true);
      for (final p in lesser) {
        expect(p.famousOrLesser?.toLowerCase().contains('lesser'), true);
      }
    });

    test('Sort by Price: Low to High and High to Low', () {
      final lowToHigh = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(selectedSort: ExploreSortOption.priceLowToHigh),
      );
      expect(lowToHigh.isNotEmpty, true);
      for (int i = 0; i < lowToHigh.length - 1; i++) {
        expect(lowToHigh[i].price <= lowToHigh[i + 1].price, true);
      }

      final highToLow = repository.searchAndFilter(
        query: '',
        filter: const ExploreFilterState(selectedSort: ExploreSortOption.priceHighToLow),
      );
      expect(highToLow.isNotEmpty, true);
      for (int i = 0; i < highToLow.length - 1; i++) {
        expect(highToLow[i].price >= highToLow[i + 1].price, true);
      }
    });

    test('Composable: Search "saree" + Filter "Tamil Nadu"', () {
      final results = repository.searchAndFilter(
        query: 'saree',
        filter: const ExploreFilterState(selectedRegion: 'Tamil Nadu'),
      );
      expect(results.isNotEmpty, true);
      for (final p in results) {
        expect(p.state == 'Tamil Nadu' || p.region.contains('Tamil Nadu'), true);
      }
    });

    test('Search with invalid query returns empty list without error', () {
      final results = repository.searchAndFilter(
        query: 'xyznonexistentcraft12345',
        filter: const ExploreFilterState(),
      );
      expect(results.isEmpty, true);
    });
  });

  group('ExploreScreen UI & Widget Tests', () {
    testWidgets('Top filter icon is removed from AppBar, ExploreSearchBar is present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header text is present
      expect(find.text('Explore Heritage Crafts'), findsOneWidget);

      // Verify AppBar actions has no standalone filter IconButton
      expect(find.byIcon(Icons.filter_list_rounded), findsNothing);
      expect(find.byIcon(Icons.filter_alt_outlined), findsNothing);

      // Verify ExploreSearchBar is present
      expect(find.byType(ExploreSearchBar), findsOneWidget);

      // Verify tune/filter icon inside search bar is present
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('Typing into search bar updates results and shows clear button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);

      // Type "saree" into search field
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'saree');
      await tester.pumpAndSettle();

      // Clear button should now be visible
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      // Search results header should appear
      expect(find.text('Search Results'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      // Query cleared and Handcrafted Discoveries restored
      expect(find.text('Handcrafted Discoveries'), findsOneWidget);
    });

    testWidgets('Invalid query displays No Crafts Found empty state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'zzzzzzzzunknown123');
      await tester.pumpAndSettle();

      expect(find.text('No Crafts Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search button
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      // Restores products
      expect(find.text('No Crafts Found'), findsNothing);
      expect(find.text('Handcrafted Discoveries'), findsOneWidget);
    });

    testWidgets('Tapping filter icon inside search bar opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tune/filter icon
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Bottom sheet should open with "Filter Crafts" and sections
      expect(find.text('Filter Crafts'), findsOneWidget);
      expect(find.text('SORT BY'), findsOneWidget);
      expect(find.text('REGION'), findsOneWidget);
      expect(find.text('CRAFT CATEGORY'), findsOneWidget);
      expect(find.text('PRICE'), findsOneWidget);
      expect(find.text('RATING'), findsOneWidget);
      expect(find.text('AVAILABILITY'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });

    testWidgets('Apply Filters (Handloom & Textiles + Tamil Nadu) updates results and shows active filter badges', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select Tamil Nadu inside bottom sheet
      final tamilNaduInSheet = find.descendant(
        of: find.byType(ExploreFilterBottomSheet),
        matching: find.text('Tamil Nadu'),
      );
      await tester.ensureVisible(tamilNaduInSheet);
      await tester.tap(tamilNaduInSheet);
      await tester.pumpAndSettle();

      // Select Handloom & Textiles inside bottom sheet
      final handloomInSheet = find.descendant(
        of: find.byType(ExploreFilterBottomSheet),
        matching: find.text('Handloom & Textiles'),
      );
      await tester.ensureVisible(handloomInSheet);
      await tester.tap(handloomInSheet);
      await tester.pumpAndSettle();

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Verify bottom sheet closed and filter badges displayed
      expect(find.text('Filter Crafts'), findsNothing);
      expect(find.text('Filtered by:'), findsOneWidget);
      expect(find.text('Handloom & Textiles'), findsAtLeastNWidgets(1));
      expect(find.text('Tamil Nadu'), findsAtLeastNWidgets(1));

      // Verify active badge count on tune icon is 2
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Composable: Filter Handloom & Textiles + Search "saree", then clear search preserves filter', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select Handloom & Textiles inside bottom sheet
      final handloomInSheet = find.descendant(
        of: find.byType(ExploreFilterBottomSheet),
        matching: find.text('Handloom & Textiles'),
      );
      await tester.ensureVisible(handloomInSheet);
      await tester.tap(handloomInSheet);
      await tester.pumpAndSettle();

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Now enter search "saree"
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'saree');
      await tester.pumpAndSettle();

      // Both are active
      expect(find.text('Filtered by:'), findsOneWidget);
      expect(find.text('Search Results'), findsOneWidget);

      // Tap clear X
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      // Search cleared, but filter is preserved!
      expect(find.text('Search Results'), findsNothing);
      expect(find.text('Filtered by:'), findsOneWidget);
      expect(find.text('Handloom & Textiles'), findsAtLeastNWidgets(1));
    });

    testWidgets('Clear all filters restores default view', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open filter bottom sheet and apply Handloom & Textiles
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      final handloomInSheet = find.descendant(
        of: find.byType(ExploreFilterBottomSheet),
        matching: find.text('Handloom & Textiles'),
      );
      await tester.ensureVisible(handloomInSheet);
      await tester.tap(handloomInSheet);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filtered by:'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Active filters bar is gone
      expect(find.text('Filtered by:'), findsNothing);
    });

    testWidgets('Localization: Tamil and Hindi render accurate translations', (tester) async {
      // Test Tamil
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('tamil_scope'),
          overrides: [
            localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('ta'))),
          ],
          child: const MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('பாரம்பரிய கைவினைகளை ஆராயுங்கள்'), findsOneWidget);
      final tamilField = tester.widget<TextField>(find.byType(TextField));
      expect(tamilField.decoration?.hintText, 'கைவினை, கைவினைஞர் அல்லது பகுதி மூலம் தேடுங்கள்...');

      // Test Hindi
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('hindi_scope'),
          overrides: [
            localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('hi'))),
          ],
          child: const MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('पारंपरिक शिल्पों का अन्वेषण करें'), findsOneWidget);
      final hindiField = tester.widget<TextField>(find.byType(TextField));
      expect(hindiField.decoration?.hintText, 'शिल्प, शिल्पकार या क्षेत्र द्वारा खोजें...');
    });

    testWidgets('Small Android screen responsiveness (320x533): no overflows', (tester) async {
      tester.view.physicalSize = const Size(320, 533);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter long multilingual text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Kanchipuram பட்டு சேலை Pure Handloom');
      await tester.pumpAndSettle();

      // Verify no exception / overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(ExploreSearchBar), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });
  });
}
