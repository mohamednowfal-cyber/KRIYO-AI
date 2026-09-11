import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Login Screens Phone Input Clean Initialization Tests', () {
    testWidgets('ArtisanLoginScreen initializes phone field as empty with hint and no border clipping',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the mobile number TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget(textFieldFinder);
      // Empty by default (no random or hardcoded numbers like 9840123456)
      expect(textField.controller?.text, isEmpty);

      // Clean hint text visible
      expect(textField.decoration?.hintText, equals('Enter 10-digit mobile number'));

      // Check +91 prefix container
      expect(find.text('+91'), findsOneWidget);

      // Typing a valid 10-digit number works without layout errors
      await tester.enterText(textFieldFinder, '9876543210');
      await tester.pumpAndSettle();
      expect(find.text('9876543210'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerLoginScreen initializes email field as empty with hint and no border clipping',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the email TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget(textFieldFinder);
      // Empty by default
      expect(textField.controller?.text, isEmpty);

      // Clean hint text visible
      expect(textField.decoration?.hintText, equals('Enter your email address'));

      // Typing a valid email works without layout errors
      await tester.enterText(textFieldFinder, 'customer@kriyo.com');
      await tester.pumpAndSettle();
      expect(find.text('customer@kriyo.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
