import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/products/edit_product_screen.dart';

void main() {
  Widget buildTestWidget({Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const EditProductScreen(id: 'prod-1'),
      ),
    );
  }

  group('EditProductScreen UI and Overlap-free Layout Tests', () {
    testWidgets('renders all initial fields, prefixes, suffixes without overlap', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Screen title in AppBar
      expect(find.text('Edit Product'), findsOneWidget);

      // Section labels
      expect(find.text('Product Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Price (₹)'), findsOneWidget);
      expect(find.text('Stock Units'), findsOneWidget);
      expect(find.text('Raw Materials'), findsOneWidget);
      expect(find.text('Technique'), findsOneWidget);
      expect(find.text('Shipping Weight'), findsOneWidget);

      // Initial values in fields
      expect(find.text('Traditional Cotton Saree'), findsOneWidget);
      expect(find.text('Handwoven using combed organic cotton and natural indigo dyes with temple border motifs.'), findsOneWidget);
      expect(find.text('2850'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Combed Cotton'), findsOneWidget);
      expect(find.text('Pit Loom Korvai'), findsOneWidget);
      expect(find.text('0.85'), findsOneWidget);

      // Verify prefix ₹ and suffix kg
      expect(find.text('₹'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);

      // Save button CTA
      expect(find.text('Save Product Details'), findsOneWidget);
    });

    testWidgets('Technique is a dropdown and selects another technique properly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap technique dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select 'Hand Block Print'
      final option = find.text('Hand Block Print').last;
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(find.text('Hand Block Print'), findsOneWidget);
    });

    testWidgets('Validation triggers when required field is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Clear product title
      final titleField = find.widgetWithText(TextFormField, 'Traditional Cotton Saree');
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();

      // Tap Save
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Product Details');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.text('Please enter a product title'), findsOneWidget);
    });

    testWidgets('Unsaved changes dialog prompts on back when modified', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Modify the title
      final titleField = find.widgetWithText(TextFormField, 'Traditional Cotton Saree');
      await tester.enterText(titleField, 'New Silk Saree');
      await tester.pumpAndSettle();

      // Tap Back button in AppBar
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Unsaved changes dialog should show
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text("Your product changes haven't been saved."), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Tap Keep Editing to dismiss dialog
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Changes'), findsNothing);
      expect(find.text('New Silk Saree'), findsOneWidget);
    });

    testWidgets('Supports Tamil (ta) localization without crashing or overflowing', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ta')));
      await tester.pumpAndSettle();

      // Verify Tamil header & labels
      expect(find.text('பொருளைத் திருத்து'), findsOneWidget);
      expect(find.text('பொருளின் பெயர்'), findsOneWidget);
      expect(find.text('விளக்கம்'), findsOneWidget);
      expect(find.text('விலை (₹)'), findsOneWidget);
      expect(find.text('பொருள் விவரங்களைச் சேமிக்கவும்'), findsOneWidget);
    });

    testWidgets('Supports Hindi (hi) localization without crashing or overflowing', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      // Verify Hindi header & labels
      expect(find.text('उत्पाद संपादित करें'), findsOneWidget);
      expect(find.text('उत्पाद का नाम'), findsOneWidget);
      expect(find.text('विवरण'), findsOneWidget);
      expect(find.text('मूल्य (₹)'), findsOneWidget);
      expect(find.text('उत्पाद विवरण सहेजें'), findsOneWidget);
    });
  });
}
