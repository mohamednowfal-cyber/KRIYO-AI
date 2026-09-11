import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/production_update_screen.dart';

void main() {
  Widget buildTestWidget({Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const ProductionUpdateScreen(),
      ),
    );
  }

  group('Update Craft Journey (ProductionUpdateScreen) Tests', () {
    testWidgets('Renders header, stage selector, workshop media buttons, and message field',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Update Craft Journey'), findsOneWidget);
      expect(find.text('Share Progress with the Buyer'), findsOneWidget);
      expect(find.text('Current Stage'), findsOneWidget);
      expect(find.text('Add Workshop Media'), findsOneWidget);

      // Verify media buttons
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Short Video'), findsOneWidget);
      expect(find.text('Voice Note'), findsOneWidget);

      // Verify artisan message
      expect(find.text('Artisan Message to Buyer'), findsOneWidget);
      expect(find.text('Send Update to Buyer'), findsOneWidget);
    });

    testWidgets('Allows selecting production stages', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open stage dropdown
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select 'Dyeing & Finishing'
      final dyeingOption = find.text('Dyeing & Finishing').last;
      await tester.tap(dyeingOption);
      await tester.pumpAndSettle();

      expect(find.text('Dyeing & Finishing'), findsOneWidget);
    });

    testWidgets('Tapping photo button opens photo picker options sheet', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Photo button
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('Tapping short video button opens video picker options sheet',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Short Video button
      await tester.tap(find.text('Short Video'));
      await tester.pumpAndSettle();

      expect(find.text('Record Video'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('Validates empty content before submission', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Clear the message field
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pump();

      // Tap Send Update
      final sendBtn = find.text('Send Update to Buyer');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Please provide content for your memory before saving.'),
        findsOneWidget,
      );
    });

    testWidgets('Submitting valid update triggers progress indicator and success SnackBar',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Update to Buyer');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      // Verify progress or submitting state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for submission completion
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Craft Journey update pushed to customer!'), findsOneWidget);
    });

    testWidgets('Multilingual rendering in Tamil and Hindi without text collision',
        (tester) async {
      // Test Tamil
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ta')));
      await tester.pumpAndSettle();

      expect(find.text('கைவினைப் பயணத்தைப் புதுப்பிக்கவும்'), findsOneWidget);
      expect(find.text('வாங்குபவருடன் முன்னேற்றத்தைப் பகிரவும்'), findsOneWidget);
      expect(find.text('தற்போதைய நிலை'), findsOneWidget);
      expect(find.text('பயிலக ஊடகத்தைச் சேர்க்கவும்'), findsOneWidget);
      expect(find.text('புகைப்படம்'), findsOneWidget);
      expect(find.text('குரல் குறிப்பு'), findsOneWidget);
      expect(find.text('வாங்குபவருக்குக் கைவினைஞரின் செய்தி'), findsOneWidget);
      expect(find.text('வாங்குபவருக்குப் புதுப்பிப்பை அனுப்பவும்'), findsOneWidget);

      // Test Hindi
      await tester.pumpWidget(buildTestWidget(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('शिल्प यात्रा अपडेट करें'), findsOneWidget);
      expect(find.text('खरीदार के साथ प्रगति साझा करें'), findsOneWidget);
      expect(find.text('वर्तमान चरण'), findsOneWidget);
      expect(find.text('कार्यशाला मीडिया जोड़ें'), findsOneWidget);
      expect(find.text('तस्वीर'), findsOneWidget);
      expect(find.text('ध्वनि नोट'), findsOneWidget);
      expect(find.text('खरीदार के लिए कारीगर का संदेश'), findsOneWidget);
      expect(find.text('खरीदार को अपडेट भेजें'), findsOneWidget);
    });
  });
}
