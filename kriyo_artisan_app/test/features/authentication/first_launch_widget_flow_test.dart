import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/localization/locale_provider.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/language/presentation/screens/global_language_selection_screen.dart';
import 'package:kriyo_artisan_app/features/role_selection/presentation/screens/role_selection_screen.dart';
import 'package:kriyo_artisan_app/shared/widgets/switch_experience_dialog.dart';

Widget createTestApp({
  required Widget child,
  UserSession session = const UserSession(),
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/welcome', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/home', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/login', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/customer/login', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/customer/home', builder: (context, state) => const SizedBox()),
    ],
  );

  return ProviderScope(
    overrides: [
      sessionProvider.overrideWith((ref) => SessionNotifier(session)),
      localeProvider.overrideWith((ref) => LocaleNotifier(locale)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('First-Launch UI Widgets Flow', () {
    testWidgets('GlobalLanguageSelectionScreen renders language options and responds to tap', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlobalLanguageSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);

      // Tap Tamil language tile
      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      // Tap Continue button
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    });

    testWidgets('RoleSelectionScreen renders Artisan and Customer cards with CTAs', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const RoleSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Role'), findsOneWidget);
      expect(find.text('ARTISAN'), findsOneWidget);
      expect(find.text('Continue as Artisan'), findsOneWidget);
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('Continue as Customer'), findsOneWidget);

      // Tap Continue as Artisan
      await tester.tap(find.text('Continue as Artisan'));
      await tester.pumpAndSettle();
    });

    testWidgets('SwitchExperienceDialog renders options and allows selecting Customer', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          session: const UserSession(
            activeRole: UserRole.artisan,
            isArtisanAuthenticated: true,
            isCustomerAuthenticated: true,
          ),
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SwitchExperienceDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Experience'), findsOneWidget);
      expect(find.text('Customer Experience'), findsOneWidget);
      expect(find.text('Artisan Studio'), findsOneWidget);

      // Tap Customer Experience
      await tester.tap(find.text('Customer Experience'));
      await tester.pumpAndSettle();

      // Continue button is rendered
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    });
  });
}
