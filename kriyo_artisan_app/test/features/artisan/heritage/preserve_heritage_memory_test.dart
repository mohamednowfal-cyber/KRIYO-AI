import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/heritage/add_heritage_memory_screen.dart';

void main() {
  Widget buildTestWidget({Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const AddHeritageMemoryScreen(),
      ),
    );
  }

  group('Preserve Heritage Memory UI & Functionality Tests', () {
    testWidgets('Displays exactly FIVE preservation options and Demonstration is removed',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify the 5 options exist
      expect(find.text('Voice Story'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Text Story'), findsOneWidget);

      // Verify Demonstration is completely removed
      expect(find.text('Demonstration'), findsNothing);

      // Verify descriptions exist
      expect(find.text('Record oral knowledge'), findsOneWidget);
      expect(find.text('Preserve visual memories'), findsOneWidget);
      expect(find.text('Capture craft techniques'), findsOneWidget);
      expect(find.text('Save historical documents'), findsOneWidget);
      expect(find.text('Write a heritage memory'), findsOneWidget);
    });

    testWidgets('Only one preservation type is active at a time and dynamic area switches',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // By default, Voice Story is active
      expect(find.text('Recording Oral Memory'), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);

      // Switch to Photo
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Preserve a Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Start Recording'), findsNothing);

      // Switch to Video
      await tester.tap(find.text('Video'));
      await tester.pumpAndSettle();

      expect(find.text('Preserve a Video'), findsOneWidget);
      expect(find.text('Record Video'), findsOneWidget);
      expect(find.text('Take Photo'), findsNothing);

      // Switch to Document
      await tester.tap(find.text('Document'));
      await tester.pumpAndSettle();

      expect(find.text('Preserve a Document'), findsOneWidget);
      expect(find.text('Choose Document'), findsOneWidget);
      expect(find.text('Record Video'), findsNothing);

      // Switch to Text Story
      await tester.tap(find.text('Text Story'));
      await tester.pumpAndSettle();

      expect(find.text('Preserve a Written Story'), findsOneWidget);
      expect(find.text('0 / 2000'), findsOneWidget);
      expect(find.text('Choose Document'), findsNothing);
    });

    testWidgets('Text Story validation and character counter works properly',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Text Story'));
      await tester.pumpAndSettle();

      // Enter story text into the story TextField (second TextField in text story mode)
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // textFields.at(1) is the story multiline text field
      await tester.enterText(textFields.at(1), "My family's heirloom weave story");
      await tester.pump();

      expect(find.text("32 / 2000"), findsOneWidget);
    });

    testWidgets('Empty save triggers validation warning SnackBar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Save Memory with empty Voice Story
      final saveBtn = find.text('Save Memory & Set Permissions');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please provide content for your memory before saving.'), findsOneWidget);
    });

    testWidgets('Multilingual rendering in Tamil and Hindi without layout overflow',
        (tester) async {
      // Test Tamil
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ta')));
      await tester.pumpAndSettle();

      expect(find.text('பாரம்பரிய நினைவைப் பாதுகாக்கவும்'), findsOneWidget);
      expect(find.text('குரல் கதை'), findsOneWidget);
      expect(find.text('புகைப்படம்'), findsOneWidget);
      expect(find.text('காணொளி'), findsOneWidget);
      expect(find.text('ஆவணம்'), findsOneWidget);
      expect(find.text('எழுத்துக் கதை'), findsOneWidget);

      // Test Hindi
      await tester.pumpWidget(buildTestWidget(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('विरासत स्मृति संजोएँ'), findsOneWidget);
      expect(find.text('ध्वनि कथा'), findsOneWidget);
      expect(find.text('तस्वीर'), findsOneWidget);
      expect(find.text('वीडियो'), findsOneWidget);
      expect(find.text('दस्तावेज़'), findsOneWidget);
      expect(find.text('लिखित कथा'), findsOneWidget);
    });
  });
}
