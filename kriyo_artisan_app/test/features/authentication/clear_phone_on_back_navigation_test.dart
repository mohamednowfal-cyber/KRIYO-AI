import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/presentation/providers/auth_provider.dart';
import 'fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createCustomerTestApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.customerLogin,
      routes: [
        GoRoute(
          path: AppRoutes.customerLogin,
          builder: (context, state) => const CustomerLoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.customerOtp,
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text('Customer OTP Screen'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: ElevatedButton(
                key: const Key('otp_back_btn'),
                onPressed: () => context.pop(),
                child: const Text('Back to Login'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const Scaffold(body: Text('Welcome Screen')),
        ),
        GoRoute(
          path: AppRoutes.customerSignUp,
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Text('Sign Up Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  Widget createArtisanTestApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const ArtisanLoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.otp,
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text('Artisan OTP Screen'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: ElevatedButton(
                key: const Key('artisan_otp_back_btn'),
                onPressed: () => context.pop(),
                child: const Text('Back to Artisan Login'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const Scaffold(body: Text('Welcome Screen')),
        ),
        GoRoute(
          path: AppRoutes.artisanSignUp,
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Text('Artisan Sign Up Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Clear Mobile Number on Back Navigation Tests', () {
    testWidgets(
        'CustomerLoginScreen: entering email, going inside to OTP, and pressing back removes the email',
        (tester) async {
      await tester.pumpWidget(createCustomerTestApp());
      await tester.pumpAndSettle();

      // Verify CustomerLoginScreen is displayed
      expect(find.text('Discover Handmade'), findsOneWidget);

      // Find the email TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Enter email address
      await tester.enterText(textFieldFinder, 'customer@kriyo.com');
      await tester.pumpAndSettle();

      // Check text entered
      expect(find.text('customer@kriyo.com'), findsOneWidget);

      // Tap the Continue button to go inside OTP
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verify we are now on the Customer OTP screen
      expect(find.text('Customer OTP Screen'), findsOneWidget);

      // Now trigger back navigation by tapping back button
      final backButton = find.byKey(const Key('otp_back_btn'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // We should be back on CustomerLoginScreen
      expect(find.text('Discover Handmade'), findsOneWidget);

      // The entered email MUST be cleared / removed!
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, isEmpty);
      expect(find.text('customer@kriyo.com'), findsNothing);
    });

    testWidgets(
        'ArtisanLoginScreen: entering number, going inside to OTP, and pressing back removes the number',
        (tester) async {
      await tester.pumpWidget(createArtisanTestApp());
      await tester.pumpAndSettle();

      // Verify ArtisanLoginScreen is displayed
      expect(find.text('ARTISAN PORTAL'), findsOneWidget);

      // Find the mobile number TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Enter a 10-digit mobile number
      await tester.enterText(textFieldFinder, '9123456789');
      await tester.pumpAndSettle();

      // Check text entered
      expect(find.text('9123456789'), findsOneWidget);

      // Tap the Continue button to go inside OTP
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verify we are now on the Artisan OTP screen
      expect(find.text('Artisan OTP Screen'), findsOneWidget);

      // Now trigger back navigation by tapping back button
      final backButton = find.byKey(const Key('artisan_otp_back_btn'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // We should be back on ArtisanLoginScreen
      expect(find.text('ARTISAN PORTAL'), findsOneWidget);

      // The entered mobile number MUST be cleared / removed!
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, isEmpty);
      expect(find.text('9123456789'), findsNothing);
    });
  });
}
