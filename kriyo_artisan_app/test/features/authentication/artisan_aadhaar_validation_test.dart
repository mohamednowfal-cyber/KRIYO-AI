import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/core/models/user_models.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/artisan_profile_provider.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_profile_setup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AadhaarNumberInputFormatter Tests', () {
    final formatter = AadhaarNumberInputFormatter();

    test('formats 12 digits with spaces every 4 characters', () {
      const input = TextEditingValue(
        text: '123456789012',
        selection: TextSelection.collapsed(offset: 12),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '1234 5678 9012');
      expect(result.selection.end, 14);
    });

    test('caps at 12 digits even if more are typed/pasted', () {
      const input = TextEditingValue(
        text: '1234567890123456',
        selection: TextSelection.collapsed(offset: 16),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '1234 5678 9012');
    });

    test('normalizes input with existing dashes and spaces', () {
      const input = TextEditingValue(
        text: '1234-5678 9012',
        selection: TextSelection.collapsed(offset: 14),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '1234 5678 9012');
    });

    test('ignores non-digit characters', () {
      const input = TextEditingValue(
        text: '1234abcd5678#@9012',
        selection: TextSelection.collapsed(offset: 18),
      );
      final result = formatter.formatEditUpdate(TextEditingValue.empty, input);
      expect(result.text, '1234 5678 9012');
    });
  });

  group('Aadhaar Masking & Session State Tests', () {
    test('UserSession maskedAadhaar returns •••• •••• last4', () {
      const session = UserSession(aadhaarNumber: '123456789012');
      expect(session.maskedAadhaar, '•••• •••• 9012');
    });

    test('UserSession maskedAadhaar returns null when not provided', () {
      const session = UserSession();
      expect(session.maskedAadhaar, isNull);
    });

    test('ArtisanProfile maskedAadhaar formats correctly', () {
      const profile = ArtisanProfile(
        userId: 'usr_123',
        primaryCraft: 'Weaving',
        yearsOfExperience: '15',
        primaryTechnique: 'Handloom',
        aadhaarNumber: '998877665544',
      );
      expect(profile.maskedAadhaar, '•••• •••• 5544');
    });

    test('ArtisanProfileModel maskedAadhaar formats correctly', () {
      const model = ArtisanProfileModel(aadhaarNumber: '112233445566');
      expect(model.maskedAadhaar, '•••• •••• 5566');
    });

    test('ArtisanProfileModel preserves already masked string', () {
      const model = ArtisanProfileModel(aadhaarNumber: '•••• •••• 9012');
      expect(model.maskedAadhaar, '•••• •••• 9012');
    });
  });

  group('ArtisanProfileSetupScreen Widget Tests', () {
    Widget createWidgetUnderTest() {
      final router = GoRouter(
        initialLocation: '/setup',
        routes: [
          GoRoute(
            path: '/setup',
            builder: (context, state) => const ArtisanProfileSetupScreen(
              artisanName: 'Ravi Kumar',
              phoneNumber: '+91 98401 23456',
            ),
          ),
          GoRoute(
            path: AppRoutes.craftSelection,
            builder: (context, state) =>
                const Scaffold(body: Text('Craft Selection Screen')),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) =>
                const Scaffold(body: Text('Login Screen')),
          ),
        ],
      );

      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets(
        'renders Aadhaar Card Number field with hint, helper text, and security banner',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for Aadhaar label (using findRichText: true)
      expect(
        find.textContaining('Aadhaar Card Number', findRichText: true),
        findsOneWidget,
      );

      // Check for Hint text
      expect(find.text('XXXX XXXX XXXX'), findsOneWidget);

      // Check for helper text
      expect(
        find.text('12-digit UIDAI number for artisan verification'),
        findsOneWidget,
      );

      // Check for Security banner
      expect(
        find.textContaining('Your Aadhaar is securely encrypted'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Continue button is disabled until valid 12-digit Aadhaar and required fields are entered',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially Continue button should be disabled because State, District, Village, Aadhaar are incomplete
      final continueButtonFinder =
          find.widgetWithText(ElevatedButton, 'Continue to Craft Information');
      expect(continueButtonFinder, findsOneWidget);
      ElevatedButton button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNull);

      // Select Gender (now required)
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      // Select state
      await tester.ensureVisible(find.text('Select state'));
      await tester.tap(find.text('Select state'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamil Nadu').last);
      await tester.pumpAndSettle();

      // Enter District
      await tester.ensureVisible(find.widgetWithText(TextField, 'Enter district'));
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter district'), 'Kanchipuram');
      await tester.pumpAndSettle();

      // Enter Village
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter village or town name'),
          'Walajabad');
      await tester.pumpAndSettle();

      // Button should still be disabled because Aadhaar is empty
      button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNull);

      // Enter incomplete 5-digit Aadhaar
      await tester.enterText(
          find.widgetWithText(TextField, 'XXXX XXXX XXXX'), '12345');
      await tester.pumpAndSettle();

      // Button should still be disabled
      button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNull);

      // Enter full 12 digits
      await tester.enterText(
          find.widgetWithText(TextField, 'XXXX XXXX XXXX'), '123456789012');
      await tester.pumpAndSettle();

      // Formatted text should have spaces
      expect(find.text('1234 5678 9012'), findsOneWidget);

      // Button should now be enabled
      button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNotNull);

      // Tap Continue and verify it navigates to craft selection
      await tester.tap(continueButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Craft Selection Screen'), findsOneWidget);
    });

    testWidgets('CustomerSetupScreen does NOT contain Aadhaar field',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aadhaar'), findsNothing);
    });
  });
}
