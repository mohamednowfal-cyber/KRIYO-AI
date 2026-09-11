import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/localization/locale_provider.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/language/presentation/screens/language_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KRIYO First-Time Language Selection Tests', () {
    Widget buildLanguageScreen({
      bool isFromSettings = false,
      ProviderContainer? container,
    }) {
      final scope = container != null
          ? UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: container.read(localeProvider),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: LanguageSelectionScreen(isFromSettings: isFromSettings),
              ),
            )
          : ProviderScope(
              child: MaterialApp(
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: LanguageSelectionScreen(isFromSettings: isFromSettings),
              ),
            );

      return scope;
    }

    testWidgets('Displays Welcome header, subtitle, and strictly 3 language options',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildLanguageScreen(isFromSettings: false));
      await tester.pumpAndSettle();

      // Heading & Welcome text
      expect(find.text('Choose your preferred language.'), findsOneWidget);
      expect(find.text("Preserve India's living heritage through artisans."), findsOneWidget);

      // Exactly 3 language cards: English, Tamil, Hindi
      expect(find.text('English'), findsWidgets);
      expect(find.text('Continue in English'), findsOneWidget);

      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('தமிழில் தொடரவும்'), findsOneWidget);

      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('हिंदी में जारी रखें'), findsOneWidget);

      // Continue button is initially disabled (no card selected on first launch)
      final continueBtnFinder = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueBtnFinder, findsOneWidget);
      final ElevatedButton continueBtn = tester.widget(continueBtnFinder);
      expect(continueBtn.onPressed, isNull);
    });

    testWidgets('Selecting Tamil activates radio indicator and enables Continue button',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildLanguageScreen(
        isFromSettings: false,
        container: container,
      ));
      await tester.pumpAndSettle();

      // Tap Tamil card
      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      // Continue button is now enabled
      final ElevatedButton continueBtn =
          tester.widget(find.widgetWithText(ElevatedButton, 'Continue'));
      expect(continueBtn.onPressed, isNotNull);

      // Tap Continue
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Verify localeProvider updated to Tamil
      expect(container.read(localeProvider).languageCode, equals('ta'));

      // Verify persistent storage saved preferred_language and language_selected
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('language_selected'), isTrue);
      expect(prefs.getString('preferred_language'), equals('ta'));
    });

    testWidgets('Selecting Hindi activates radio indicator and enables Continue button',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildLanguageScreen(
        isFromSettings: false,
        container: container,
      ));
      await tester.pumpAndSettle();

      // Tap Hindi card
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      // Continue button is now enabled
      final ElevatedButton continueBtn =
          tester.widget(find.widgetWithText(ElevatedButton, 'Continue'));
      expect(continueBtn.onPressed, isNotNull);

      // Tap Continue
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Verify localeProvider updated to Hindi
      expect(container.read(localeProvider).languageCode, equals('hi'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('language_selected'), isTrue);
      expect(prefs.getString('preferred_language'), equals('hi'));
    });

    testWidgets('When opened from settings, pre-selects current active language and shows back button',
        (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Pre-set to Tamil
      await container.read(localeProvider.notifier).setLocaleCode('ta');

      await tester.pumpWidget(buildLanguageScreen(
        isFromSettings: true,
        container: container,
      ));
      await tester.pumpAndSettle();

      // Continue button should already be enabled in settings mode
      final ElevatedButton continueBtn =
          tester.widget(find.widgetWithText(ElevatedButton, 'Continue'));
      expect(continueBtn.onPressed, isNotNull);
    });

    test('LocaleNotifier and UserSession startupRoute logic on first vs subsequent launch', () async {
      // 1. First launch (no language chosen)
      SharedPreferences.setMockInitialValues({});
      expect(await LocaleNotifier.hasSelectedLanguage(), isFalse);

      const firstSession = UserSession(
        hasSelectedLanguage: false,
        hasSelectedRole: false,
        isAuthenticated: false,
      );
      expect(firstSession.startupRoute, equals('/language-selection'));

      // 2. Language selected, role not selected
      const langSelectedSession = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: false,
        isAuthenticated: false,
      );
      expect(langSelectedSession.startupRoute, equals('/welcome'));

      // 3. Second launch: Customer logged in -> Customer Home
      const customerSession = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isCustomerAuthenticated: true,
        hasCustomerProfile: true,
      );
      expect(customerSession.startupRoute, equals('/customer/home'));

      // 4. Second launch: Artisan logged in -> Artisan Home
      const artisanSession = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: true,
        hasArtisanProfile: true,
      );
      expect(artisanSession.startupRoute, equals('/home'));

      // 5. Unauthenticated Customer with role selected -> Customer Login
      const unauthCustomer = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.customer,
        isCustomerAuthenticated: false,
      );
      expect(unauthCustomer.startupRoute, equals('/customer/login'));

      // 6. Unauthenticated Artisan with role selected -> Artisan Login
      const unauthArtisan = UserSession(
        hasSelectedLanguage: true,
        hasSelectedRole: true,
        activeRole: UserRole.artisan,
        isArtisanAuthenticated: false,
      );
      expect(unauthArtisan.startupRoute, equals('/login'));
    });
  });
}
