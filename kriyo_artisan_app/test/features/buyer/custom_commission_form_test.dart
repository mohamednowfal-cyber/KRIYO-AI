import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/custom_commission_screen.dart';
import 'package:kriyo_artisan_app/shared/inputs/kriyo_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestScreen() {
    return const ProviderScope(
      child: MaterialApp(
        home: CustomCommissionScreen(),
      ),
    );
  }

  group('Custom Commission Form - UI & Overflow Safeguards', () {
    testWidgets('Renders all fields without overflow on standard mobile viewport',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Custom Commission'), findsOneWidget);
      expect(find.text('Select Craft'), findsOneWidget);
      expect(find.text('Select Artisan'), findsOneWidget);
      expect(find.text('Product Type'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Budget (₹)'), findsOneWidget);
      expect(find.text('Preferred Materials'), findsOneWidget);
      expect(find.text('Dimensions / Sizing'), findsOneWidget);
      expect(find.text('Required Date'), findsOneWidget);
      expect(find.text('Describe Your Custom Requirement'), findsOneWidget);
      expect(find.text('Send Commission Inquiry'), findsOneWidget);

      // Verify KriyoTextField is used for the key input fields
      expect(find.byType(KriyoTextField), findsNWidgets(5));
      // Verify prefix '₹ ' is rendered for Budget
      expect(find.text('₹ '), findsOneWidget);
    });

    testWidgets('Supports long multiline input in custom requirement without crashing',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final multilineFinder = find.widgetWithText(
        KriyoTextField,
        'Describe Your Custom Requirement',
      );
      expect(multilineFinder, findsOneWidget);

      const longText = 'We need a bespoke temple border saree woven with 3-ply pure mulberry silk. '
          'Motifs should feature ancient peacock and lotus glyphs inspired by the Chola dynasty bronze carvings. '
          'The pallu must feature gold zari threads with antique matte finish.';

      await tester.enterText(
        find.descendant(of: multilineFinder, matching: find.byType(TextFormField)),
        longText,
      );
      await tester.pumpAndSettle();

      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('Validates missing required fields on submit attempt',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Scroll to submit button and tap without entering required product type
      await tester.scrollUntilVisible(
        find.text('Send Commission Inquiry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Send Commission Inquiry'));
      await tester.pumpAndSettle();

      // Snack bar should show validation warning
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Please specify the Product Type and Describe Your Custom Requirement.'),
        findsOneWidget,
      );
    });
  });
}
