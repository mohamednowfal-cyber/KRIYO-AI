import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/l10n/app_localizations.dart';
import 'package:kriyo_artisan_app/app/theme/app_colors.dart';
import 'package:kriyo_artisan_app/features/artisan/craft/artisan_craft_provider.dart';
import 'package:kriyo_artisan_app/features/artisan/craft/my_craft_screen.dart';

void main() {
  Widget createTestWidget({required ArtisanCraftModel craftModel}) {
    return ProviderScope(
      overrides: [
        artisanCraftProvider.overrideWith((ref) => _FakeArtisanCraftNotifier(craftModel)),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: MyCraftScreen(),
      ),
    );
  }

  group('MyCraftScreen UI Refinements Test', () {
    testWidgets('Empty state displays exactly ONE terracotta Add Photo button, no grey button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        craftModel: const ArtisanCraftModel(
          craftImagePath: null,
          isVerified: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify empty state texts
      expect(find.text('No Craft Photo Yet'), findsOneWidget);
      expect(find.text('Add a clear photo of your craft or loom'), findsOneWidget);

      // Verify there is exactly ONE "Add Photo" button in the entire screen
      final addPhotoButtonFinder = find.widgetWithText(ElevatedButton, 'Add Photo');
      expect(addPhotoButtonFinder, findsOneWidget);

      // Verify its color is primary terracotta
      final elevatedButton = tester.widget<ElevatedButton>(addPhotoButtonFinder);
      expect(
        elevatedButton.style?.backgroundColor?.resolve({}),
        equals(AppColors.primary),
      );

      // Assert that there are NO other Add Photo text or duplicate grey buttons
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('Change Photo'), findsNothing);
    });

    testWidgets('Verification badge renders in top corner when isVerified is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        craftModel: const ArtisanCraftModel(
          craftImagePath: null,
          isVerified: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Verified badge icon and text must be found
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('KRIYO VERIFIED ARTISAN'), findsOneWidget);
    });

    testWidgets('Verification badge is hidden when isVerified is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        craftModel: const ArtisanCraftModel(
          craftImagePath: null,
          isVerified: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Badge must not exist
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
      expect(find.text('KRIYO VERIFIED ARTISAN'), findsNothing);
    });

    testWidgets('Photo present state displays Change Photo and hides empty state Add Photo button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        craftModel: const ArtisanCraftModel(
          craftImagePath: 'assets/images/craft_sample.jpg',
          isVerified: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Empty state text must not exist
      expect(find.text('No Craft Photo Yet'), findsNothing);
      expect(find.text('Add Photo'), findsNothing);

      // Change photo pill must exist
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });
  });
}

class _FakeArtisanCraftNotifier extends StateNotifier<ArtisanCraftModel>
    implements ArtisanCraftNotifier {
  _FakeArtisanCraftNotifier(super.state);

  @override
  Future<void> setCraftImage(String path) async {
    state = state.copyWith(craftImagePath: path);
  }

  @override
  Future<void> removeCraftImage() async {
    state = state.copyWith(clearImage: true);
  }

  @override
  Future<void> updateCraftDetails({
    required String craftName,
    required String category,
    required String location,
    required String specialization,
    required String description,
    required List<String> techniques,
    required List<String> materials,
    required String heritageSummary,
  }) async {}
}
