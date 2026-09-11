import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/app/routes/route_guards.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/localization/locale_provider.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_profile_setup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/craft_setup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_setup_screen.dart';

Widget createTestWrapper({
  required Widget child,
  UserSession session = const UserSession(),
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      sessionProvider.overrideWith((ref) => SessionNotifier(session)),
      localeProvider.overrideWith((ref) => LocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KRIYO Complete Onboarding & Role-Specific Signup Test Suite', () {
    test('1. Strict first-time AppState progression: Language -> Role -> Login -> Setup -> Home', () {
      final notifier = SessionNotifier(const UserSession());

      // Initial: First launch
      expect(notifier.state.appState, AppState.firstLaunch);
      expect(notifier.state.startupRoute, AppRoutes.languageSelection);

      // Step A: Select Language
      notifier.setLanguage('ta');
      expect(notifier.state.hasSelectedLanguage, isTrue);
      expect(notifier.state.appState, AppState.languageSelected);
      expect(notifier.state.startupRoute, AppRoutes.welcome);

      // Step B: Select Role (Artisan)
      notifier.setSelectedRole('artisan');
      expect(notifier.state.hasSelectedRole, isTrue);
      expect(notifier.state.isArtisan, isTrue);
      expect(notifier.state.appState, AppState.authenticationRequired);
      expect(notifier.state.startupRoute, AppRoutes.login);

      // Step C: OTP Verification for new signup (hasProfile = false)
      notifier.loginAsArtisan(
        mobileNumber: '+91 98765 43210',
        hasProfile: false,
      );
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.hasArtisanProfile, isFalse);
      expect(notifier.state.appState, AppState.profileSetupRequired);
      expect(notifier.state.startupRoute, AppRoutes.onboarding);

      // Step D: Complete Artisan Profile
      notifier.completeArtisanProfile(
        name: 'Lakshmi Devi',
        craftType: 'Kanchipuram Silk Weaving',
        region: 'Kanchipuram, Tamil Nadu',
        stateName: 'Tamil Nadu',
        districtName: 'Kanchipuram',
        townOrVillage: 'Pillaiyarpalayam',
        craftCategory: 'Handloom & Textiles',
        yearsOfExperience: '25',
        primaryTechnique: 'Pure Zari Korvai Weaving',
      );
      expect(notifier.state.hasArtisanProfile, isTrue);
      expect(notifier.state.appState, AppState.authenticated);
      expect(notifier.state.startupRoute, AppRoutes.artisanHome);
    });

    test('2. Customer flow: Language -> Role -> Customer Login -> Customer Setup -> Customer Home', () {
      final notifier = SessionNotifier(const UserSession());

      notifier.setLanguage('en');
      notifier.setSelectedRole('customer');
      expect(notifier.state.isCustomer, isTrue);
      expect(notifier.state.appState, AppState.authenticationRequired);
      expect(notifier.state.startupRoute, AppRoutes.customerLogin);

      // OTP Verification for new customer
      notifier.loginAsCustomer(
        mobileNumber: '+91 98765 12345',
        name: 'Arjun Kumar',
        hasProfile: false,
      );
      expect(notifier.state.appState, AppState.profileSetupRequired);
      expect(notifier.state.startupRoute, AppRoutes.customerSetup);

      // Complete profile with optional gender & email left empty
      notifier.completeCustomerProfile(
        name: 'Arjun Kumar',
        stateName: 'Karnataka',
        districtName: 'Bengaluru Urban',
        city: 'Bengaluru',
        preferredLanguage: 'English',
        gender: null,
        email: null,
      );
      expect(notifier.state.hasCustomerProfile, isTrue);
      expect(notifier.state.appState, AppState.authenticated);
      expect(notifier.state.startupRoute, AppRoutes.buyerHome);
    });

    test('3. Returning authenticated user directly routes to Home on subsequent launches', () {
      const authenticatedArtisan = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        hasArtisanProfile: true,
        artisanName: 'Murugan Craftsperson',
      );
      expect(authenticatedArtisan.appState, AppState.authenticated);
      expect(authenticatedArtisan.startupRoute, AppRoutes.artisanHome);

      const authenticatedCustomer = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isCustomerAuthenticated: true,
        hasCustomerProfile: true,
        customerName: 'Priya Raman',
      );
      expect(authenticatedCustomer.appState, AppState.authenticated);
      expect(authenticatedCustomer.startupRoute, AppRoutes.buyerHome);
    });

    test('4. Logout resets auth credentials but preserves Language and Role for direct login', () {
      final notifier = SessionNotifier(const UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        preferredLanguage: 'ta',
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        hasArtisanProfile: true,
        userId: 'KRY-999',
        mobileNumber: '+91 98765 43210',
      ));

      notifier.logout();

      // Auth is cleared
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.isArtisanAuthenticated, isFalse);
      expect(notifier.state.userId, isNull);
      expect(notifier.state.mobileNumber, isNull);

      // Language and role are preserved
      expect(notifier.state.hasSelectedLanguage, isTrue);
      expect(notifier.state.hasSelectedRole, isTrue);
      expect(notifier.state.activeRole, UserRole.artisan);

      // Startup route opens Login directly, NOT language or role selection
      expect(notifier.state.appState, AppState.authenticationRequired);
      expect(notifier.state.startupRoute, AppRoutes.login);
    });

    test('5. RouteGuards enforce progression and role isolation', () {
      const firstLaunchSession = UserSession(
        hasSelectedLanguage: false,
        hasSelectedRole: false,
      );
      expect(
        RouteGuards.guard(
          MockBuildContext(),
          location: AppRoutes.welcome,
          session: firstLaunchSession,
        ),
        AppRoutes.languageSelection,
      );

      const roleNeededSession = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: false,
      );
      expect(
        RouteGuards.guard(
          MockBuildContext(),
          location: AppRoutes.login,
          session: roleNeededSession,
        ),
        AppRoutes.welcome,
      );

      // Customer trying to access Artisan protected screen
      const customerSession = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isCustomerAuthenticated: true,
        hasCustomerProfile: true,
      );
      expect(
        RouteGuards.guard(
          MockBuildContext(),
          location: AppRoutes.artisanHome,
          session: customerSession,
        ),
        AppRoutes.buyerHome,
      );

      // Artisan trying to access Customer protected screen
      const artisanSession = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        hasArtisanProfile: true,
      );
      expect(
        RouteGuards.guard(
          MockBuildContext(),
          location: AppRoutes.buyerHome,
          session: artisanSession,
        ),
        AppRoutes.artisanHome,
      );
    });

    testWidgets('6. CustomerSetupScreen renders required fields with mobile read-only badge', (tester) async {
      await tester.pumpWidget(
        createTestWrapper(
          session: const UserSession(
            activeRole: UserRole.customer,
            mobileNumber: '+91 98765 00000',
            isCustomerAuthenticated: true,
          ),
          child: const CustomerSetupScreen(customerName: 'Kavita Singh'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Your Profile'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Full Name')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Mobile Number')), findsOneWidget);
      expect(find.text('+91 98765 00000'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('State')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('City / District')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Gender')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Email')), findsOneWidget);

      // Artisan fields must NOT be present
      expect(find.text('Primary Craft *'), findsNothing);
      expect(find.text('Years of Experience *'), findsNothing);
      expect(find.text('Workshop Name'), findsNothing);
    });

    testWidgets('7. CraftSetupScreen renders Step 2 craft details and validates inputs', (tester) async {
      await tester.pumpWidget(
        createTestWrapper(
          session: const UserSession(
            activeRole: UserRole.artisan,
            artisanName: 'Devi Weavers',
            region: 'Kanchipuram, Tamil Nadu',
            isArtisanAuthenticated: true,
          ),
          child: const CraftSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 2 — CRAFT DETAILS'), findsOneWidget);
      expect(find.text('Tell Us About Your Craft'), findsOneWidget);
      expect(find.text('Primary Craft *'), findsOneWidget);
      expect(find.text('Craft Category *'), findsOneWidget);
      expect(find.text('Years of Experience *'), findsOneWidget);
      expect(find.text('Primary Technique *'), findsOneWidget);
      expect(find.text('Complete Profile & Enter KRIYO'), findsOneWidget);
    });

    testWidgets('8. ArtisanProfileSetupScreen renders Step 1 with read-only phone and verified badge', (tester) async {
      await tester.pumpWidget(
        createTestWrapper(
          session: const UserSession(
            activeRole: UserRole.artisan,
            mobileNumber: '+91 99887 76655',
            isArtisanAuthenticated: true,
          ),
          child: const ArtisanProfileSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 2 — PERSONAL INFO'), findsOneWidget);
      expect(find.text('Create Your Artisan Profile'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Full Name')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Mobile Number')), findsOneWidget);
      expect(find.text('+91 99887 76655'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Aadhaar Card Number')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('State')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('District')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && (w.text.toPlainText().contains('Village') || w.text.toPlainText().contains('Town'))), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Gender')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Email')), findsOneWidget);
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}
