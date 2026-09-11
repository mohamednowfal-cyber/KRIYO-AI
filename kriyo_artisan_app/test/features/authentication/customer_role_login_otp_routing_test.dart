import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/localization/locale_provider.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_otp_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:kriyo_artisan_app/features/role_selection/presentation/screens/role_selection_screen.dart';
import 'fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Customer Role Selection -> Login -> OTP -> Home Routing Flow Tests', () {
    testWidgets(
        'Clicking Customer in RoleSelectionScreen routes to CustomerLoginScreen (NOT home)',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? currentPath;
      final router = GoRouter(
        initialLocation: AppRoutes.welcome,
        routes: [
          GoRoute(
            path: AppRoutes.welcome,
            builder: (context, state) {
              currentPath = AppRoutes.welcome;
              return const RoleSelectionScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.customerLogin,
            builder: (context, state) {
              currentPath = AppRoutes.customerLogin;
              return const CustomerLoginScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.buyerHome,
            builder: (context, state) {
              currentPath = AppRoutes.buyerHome;
              return const Scaffold(body: Text('Customer Home Screen'));
            },
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(
                const UserSession(
                  hasSelectedLanguage: true,
                  hasSelectedRole: false,
                  isAuthenticated: false,
                  isCustomerAuthenticated: false,
                ),
              )),
          localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('en'))),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: on Role Selection screen
      expect(find.text('Choose Your Role'), findsOneWidget);
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('Continue as Customer'), findsOneWidget);

      // Tap Customer card
      await tester.ensureVisible(find.text('Continue as Customer'));
      await tester.tap(find.text('Continue as Customer'));
      await tester.pumpAndSettle();

      // Critical requirement: MUST route to CustomerLoginScreen, NOT buyerHome!
      expect(currentPath, equals(AppRoutes.customerLogin));
      expect(find.byType(CustomerLoginScreen), findsOneWidget);
      expect(find.text('Customer Home Screen'), findsNothing);
      expect(find.text('Discover Handmade'), findsOneWidget);
    });

    testWidgets(
        'Complete customer flow: Role Selection -> Login -> OTP -> Customer Home',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? currentPath;
      final router = GoRouter(
        initialLocation: AppRoutes.welcome,
        routes: [
          GoRoute(
            path: AppRoutes.welcome,
            builder: (context, state) {
              currentPath = AppRoutes.welcome;
              return const RoleSelectionScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.customerLogin,
            builder: (context, state) {
              currentPath = AppRoutes.customerLogin;
              return const CustomerLoginScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.customerOtp,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CustomerOtpScreen(
                email: extra?['email'] ?? 'customer@kriyo.com',
                phoneNumber: extra?['phone'] ?? '9876543210',
                isSignUp: extra?['isSignUp'] ?? false,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.buyerHome,
            builder: (context, state) {
              currentPath = AppRoutes.buyerHome;
              return const Scaffold(body: Text('Customer Home Screen'));
            },
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(
                const UserSession(
                  hasSelectedLanguage: true,
                  hasSelectedRole: false,
                  isAuthenticated: false,
                  isCustomerAuthenticated: false,
                ),
              )),
          localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('en'))),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Role Selection: Tap Customer
      await tester.ensureVisible(find.text('Continue as Customer'));
      await tester.tap(find.text('Continue as Customer'));
      await tester.pumpAndSettle();

      expect(currentPath, equals(AppRoutes.customerLogin));
      expect(find.byType(CustomerLoginScreen), findsOneWidget);

      // 2. Customer Login: Enter email
      await tester.enterText(find.byType(TextField), 'customer@kriyo.com');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // 3. Customer OTP Screen arrives
      expect(find.byType(CustomerOtpScreen), findsOneWidget);
      expect(find.text('Verify Your Email'), findsOneWidget);

      // Verify OTP screen has Verify & Continue button
      expect(find.text('Verify & Continue'), findsOneWidget);

      // Enter 6-digit OTP into the 6 cells
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 4. Then and ONLY then does Customer Home Screen arrive
      expect(currentPath, equals(AppRoutes.buyerHome));
      expect(find.text('Customer Home Screen'), findsOneWidget);
    });

    test('loadFromStorage does not mark customer authenticated when hasRole is false', () async {
      SharedPreferences.setMockInitialValues({
        'kriyo_has_selected_language': true,
        'kriyo_has_selected_role': false,
        'kriyo_is_authenticated': true,
        'kriyo_customer_authenticated': true,
        'kriyo_active_role': 'customer',
      });

      final session = await UserSession.loadFromStorage();
      expect(session.hasSelectedRole, isFalse);
      expect(session.isCustomerAuthenticated, isFalse);
      expect(session.isArtisanAuthenticated, isFalse);
    });
  });
}
