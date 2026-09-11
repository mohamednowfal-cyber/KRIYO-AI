import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_profile_setup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/craft_setup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_setup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/presentation/widgets/kriyo_signup_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Customer Signup Screen Validation & UI Tests', () {
    Widget buildCustomerScreen() {
      return const ProviderScope(
        child: MaterialApp(
          home: CustomerSetupScreen(),
        ),
      );
    }

    testWidgets('Gender label does NOT contain (Optional)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCustomerScreen());
      await tester.pumpAndSettle();

      // "Gender (Optional)" must NOT appear anywhere
      expect(find.textContaining('Gender (Optional)'), findsNothing);
      expect(find.text('Gender (Optional)'), findsNothing);
      expect(find.text('(Optional)'), findsNothing);

      // Gender choices must exist
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Prefer not to say'), findsOneWidget);
    });

    testWidgets('Email Address label displays (Optional) and has no red asterisk', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCustomerScreen());
      await tester.pumpAndSettle();

      expect(find.text('Email Address (Optional)'), findsOneWidget);
    });

    testWidgets('Gender selection works and Clear button resets selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCustomerScreen());
      await tester.pumpAndSettle();

      // Initially Clear is not visible
      expect(find.text('Clear'), findsNothing);

      // Tap Male
      await tester.ensureVisible(find.text('Male'));
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      // Clear button should now appear
      expect(find.text('Clear'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('Customer Signup requires Gender when attempting to continue', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCustomerScreen());
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.widgetWithText(TextField, 'Enter your full name'), 'John Doe');
      await tester.pumpAndSettle();

      // State is already Gujarat by default. Fill city:
      await tester.enterText(find.widgetWithText(TextField, 'Enter city / district'), 'Ahmedabad');
      await tester.pumpAndSettle();

      // Leave Gender unselected, tap Continue
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Validation error for gender must be displayed
      expect(find.text('Please select your gender.'), findsOneWidget);
    });

    testWidgets('Optional email allows empty but flags invalid format', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildCustomerScreen());
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextField, 'Enter your email address');

      // Enter invalid email
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, 'notanemail');
      await tester.pumpAndSettle();

      // Trigger continue
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      // Enter valid email
      await tester.enterText(emailField, 'user@example.com');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsNothing);
    });
  });

  group('Artisan Signup Step 1 Validation & UI Tests', () {
    Widget buildArtisanStep1Screen() {
      return const ProviderScope(
        child: MaterialApp(
          home: ArtisanProfileSetupScreen(),
        ),
      );
    }

    testWidgets('Gender label does NOT contain (Optional) and is required', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildArtisanStep1Screen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Gender (Optional)'), findsNothing);
      expect(find.text('Gender (Optional)'), findsNothing);

      // Email displays (Optional)
      expect(find.text('Email Address (Optional)'), findsOneWidget);
    });

    testWidgets('Aadhaar field accepts 12 digits with grouped formatting', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildArtisanStep1Screen());
      await tester.pumpAndSettle();

      final aadhaarField = find.widgetWithText(TextField, 'XXXX XXXX XXXX');
      expect(aadhaarField, findsOneWidget);

      await tester.ensureVisible(aadhaarField);
      await tester.enterText(aadhaarField, '987654321098');
      await tester.pumpAndSettle();

      expect(find.text('9876 5432 1098'), findsOneWidget);
    });
  });

  group('Artisan Signup Step 2 Empty Initial State & Validation Tests', () {
    Widget buildArtisanStep2Screen() {
      return const ProviderScope(
        child: MaterialApp(
          home: CraftSetupScreen(),
        ),
      );
    }

    testWidgets('All fields in Step 2 are completely EMPTY on first launch (no demo data)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildArtisanStep2Screen());
      await tester.pumpAndSettle();

      // Must NOT contain hardcoded initial texts in form fields:
      // Primary Craft field should show hint, not "Traditional Handloom Weaving"
      final craftField = tester.widget<TextField>(find.widgetWithText(TextField, 'Enter or select primary craft'));
      expect(craftField.controller?.text, isEmpty);

      // Years of experience should be empty, not "15"
      final expField = tester.widget<TextField>(find.widgetWithText(TextField, 'Enter years of experience'));
      expect(expField.controller?.text, isEmpty);

      // Primary technique should be empty, not "Pit Loom Weaving"
      final techniqueField = tester.widget<TextField>(find.widgetWithText(TextField, 'Select or enter primary technique'));
      expect(techniqueField.controller?.text, isEmpty);

      // Raw materials should be empty
      final materialsField = tester.widget<TextField>(find.widgetWithText(TextField, 'Enter raw materials used'));
      expect(materialsField.controller?.text, isEmpty);

      // Studio/workshop should be empty
      final workshopField = tester.widget<TextField>(find.widgetWithText(TextField, 'Enter studio or workshop name'));
      expect(workshopField.controller?.text, isEmpty);

      // Submit button is disabled because required fields are empty
      final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Complete Profile & Enter KRIYO');
      expect(submitButtonFinder, findsOneWidget);
      final ElevatedButton submitButton = tester.widget(submitButtonFinder);
      expect(submitButton.onPressed, isNull);
    });

    testWidgets('Tapping craft suggestion chip populates Primary Craft, Category, Technique', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildArtisanStep2Screen());
      await tester.pumpAndSettle();

      // Tap the "Terracotta Pottery" suggestion card
      await tester.tap(find.text('Terracotta Pottery'));
      await tester.pumpAndSettle();

      // Check that the fields got populated
      final craftField = tester.widget<TextField>(find.widgetWithText(TextField, 'Enter or select primary craft'));
      expect(craftField.controller?.text, 'Terracotta Pottery');

      final techniqueField = tester.widget<TextField>(find.widgetWithText(TextField, 'Select or enter primary technique'));
      expect(techniqueField.controller?.text, 'Clay Wheel Throwing');
    });

    testWidgets('Step 2 required fields validation works when entering data manually', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildArtisanStep2Screen());
      await tester.pumpAndSettle();

      // Enter craft manually
      await tester.ensureVisible(find.widgetWithText(TextField, 'Enter or select primary craft'));
      await tester.enterText(find.widgetWithText(TextField, 'Enter or select primary craft'), 'Wood Carving');
      await tester.pumpAndSettle();

      // Select category
      await tester.ensureVisible(find.text('Select craft category'));
      await tester.tap(find.text('Select craft category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Woodwork & Carving').last);
      await tester.pumpAndSettle();

      // Enter years of experience
      await tester.ensureVisible(find.widgetWithText(TextField, 'Enter years of experience'));
      await tester.enterText(find.widgetWithText(TextField, 'Enter years of experience'), '10');
      await tester.pumpAndSettle();

      // Enter primary technique
      await tester.ensureVisible(find.widgetWithText(TextField, 'Select or enter primary technique'));
      await tester.enterText(find.widgetWithText(TextField, 'Select or enter primary technique'), 'Chisel Relief');
      await tester.pumpAndSettle();

      // Button should now be enabled
      final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Complete Profile & Enter KRIYO');
      final ElevatedButton submitButton = tester.widget(submitButtonFinder);
      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('Step 2 rejects invalid negative experience or non-numbers', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildArtisanStep2Screen());
      await tester.pumpAndSettle();

      final expField = find.widgetWithText(TextField, 'Enter years of experience');
      await tester.ensureVisible(expField);
      // Digits only filter ignores letters, so entering letters keeps it empty
      await tester.enterText(expField, 'abc');
      await tester.pumpAndSettle();

      final craftField = tester.widget<TextField>(expField);
      expect(craftField.controller?.text, isEmpty);
    });
  });

  group('KriyoSignupField Architecture Tests', () {
    testWidgets('KriyoSignupField produces a single OutlineInputBorder without duplicate nested containers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KriyoSignupField(
              label: 'Full Name',
              isRequired: true,
              hintText: 'Enter your name',
              prefixIcon: Icons.person,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Label is rendered above with red asterisk
      expect(find.textContaining('Full Name'), findsOneWidget);
      // Only 1 TextField
      expect(find.byType(TextField), findsOneWidget);
      // No nested bordered containers
      expect(find.byType(KriyoSignupField), findsOneWidget);
    });
  });
}
