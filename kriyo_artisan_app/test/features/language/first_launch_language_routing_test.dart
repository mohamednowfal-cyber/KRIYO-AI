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
import 'package:kriyo_artisan_app/features/language/presentation/screens/language_selection_screen.dart';
import 'package:kriyo_artisan_app/features/role_selection/presentation/screens/role_selection_screen.dart';
import 'package:kriyo_artisan_app/features/splash/presentation/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('First-Time App Open Language Selection Routing Tests', () {
    testWidgets('First opening: Splash routes to LanguageSelectionScreen, then to RoleSelection',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});

      late GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: AppRoutes.languageSelection,
            builder: (context, state) =>
                const LanguageSelectionScreen(isFromSettings: false),
          ),
          GoRoute(
            path: AppRoutes.welcome,
            builder: (context, state) => const RoleSelectionScreen(),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(
                const UserSession(
                  hasSelectedLanguage: false,
                  hasSelectedRole: false,
                  isAuthenticated: false,
                ),
              )),
          localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('en'))),
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

      // Fast forward past splash animation (1.8s)
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      // Verified: on first open, Language Selection screen appears before Role Selection
      expect(find.text('Choose your preferred language.'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);

      // Select Tamil
      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Verified: routes to Role Selection ("Choose Your Role")
      expect(find.text('Choose Your Role'), findsOneWidget);
      expect(find.text('ARTISAN'), findsOneWidget);
      expect(find.text('CUSTOMER'), findsOneWidget);

      // Verified: NO back button to language selection on Role Selection screen
      expect(find.byTooltip('Back to Language Selection'), findsNothing);
    });

    testWidgets('Authenticated opening: Splash routes directly to Artisan Home',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: AppRoutes.languageSelection,
            builder: (context, state) =>
                const LanguageSelectionScreen(isFromSettings: false),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Artisan Home Screen')),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => SessionNotifier(
                const UserSession(
                  hasSelectedLanguage: true,
                  hasSelectedRole: true,
                  isAuthenticated: true,
                  isArtisanAuthenticated: true,
                  hasArtisanProfile: true,
                  activeRole: UserRole.artisan,
                ),
              )),
          localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('ta'))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ta'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );

      // Advance past splash
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      // Verified: Language Selection screen is SKIPPED for authenticated user, directly arrives at Home
      expect(find.text('Choose your preferred language.'), findsNothing);
      expect(find.text('Artisan Home Screen'), findsOneWidget);
    });
  });
}
