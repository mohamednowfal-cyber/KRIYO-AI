import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/l10n/app_localizations.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/buyer/settings/customer_settings_screen.dart';

void main() {
  Widget createTestWidget({
    required UserSession session,
    Locale locale = const Locale('en'),
    double screenWidth = 360,
  }) {
    return ProviderScope(
      overrides: [
        sessionProvider.overrideWith((ref) => SessionNotifier(session)),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ta'),
          Locale('hi'),
        ],
        home: MediaQuery(
          data: MediaQueryData(size: Size(screenWidth, 800)),
          child: const CustomerSettingsScreen(),
        ),
      ),
    );
  }

  group('Customer Settings - Switch Experience to Artisan UI Tests', () {
    testWidgets('Renders dedicated, professional switch card with icon, title, description, and arrow',
        (WidgetTester tester) async {
      const initialSession = UserSession(
        isAuthenticated: true,
        activeRole: UserRole.customer,
        hasArtisanProfile: true,
        hasCustomerProfile: true,
        customerCart: [
          CustomerCartItem(
            id: 'item-1',
            title: 'Silk Saree',
            artisanName: 'Lakshmi',
            craftType: 'Weaving',
            region: 'Kanchipuram',
            price: 5000,
            imageUrl: '',
          ),
        ],
        customerWishlistIds: {'item-1'},
      );

      await tester.pumpWidget(createTestWidget(session: initialSession));
      await tester.pumpAndSettle();

      // Verify section title
      expect(find.text('EXPERIENCE'), findsOneWidget);

      // Verify vector icon
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

      // Verify title & description text
      expect(find.text('Switch the Experience to Artisan'), findsOneWidget);
      expect(
        find.text('Manage your crafts, products and artisan profile'),
        findsOneWidget,
      );

      // Verify right-side arrow
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Verify semantics label
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Switch to Artisan experience',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Responsive safety on narrow screen width (300dp) with zero RenderFlex overflow',
        (WidgetTester tester) async {
      const session = UserSession(
        isAuthenticated: true,
        activeRole: UserRole.customer,
        hasArtisanProfile: true,
      );

      await tester.pumpWidget(createTestWidget(session: session, screenWidth: 300));
      await tester.pumpAndSettle();

      // Text and arrow must both be found without any exception
      expect(find.text('Switch the Experience to Artisan'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping switch card with existing Artisan session shows confirmation dialog and preserves customer data',
        (WidgetTester tester) async {
      const initialSession = UserSession(
        isAuthenticated: true,
        activeRole: UserRole.customer,
        hasArtisanProfile: true,
        hasCustomerProfile: true,
        customerCart: [
          CustomerCartItem(
            id: 'item-1',
            title: 'Silk Saree',
            artisanName: 'Lakshmi',
            craftType: 'Weaving',
            region: 'Kanchipuram',
            price: 5000,
            imageUrl: '',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(session: initialSession));
      await tester.pumpAndSettle();

      // Tap the Switch Experience card
      await tester.tap(find.text('Switch the Experience to Artisan'));
      await tester.pumpAndSettle();

      // Lightweight confirmation dialog should appear
      expect(find.text('Switch to Artisan Experience?'), findsOneWidget);
      expect(find.text("You'll enter your artisan workspace."), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel - dismisses dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to Artisan Experience?'), findsNothing);
    });

    testWidgets('Tapping switch card when NO Artisan account exists displays login/signup action sheet',
        (WidgetTester tester) async {
      const sessionWithoutArtisan = UserSession(
        isAuthenticated: true,
        activeRole: UserRole.customer,
        hasArtisanProfile: false,
      );

      await tester.pumpWidget(createTestWidget(session: sessionWithoutArtisan));
      await tester.pumpAndSettle();

      // Tap the Switch Experience card
      await tester.tap(find.text('Switch the Experience to Artisan'));
      await tester.pumpAndSettle();

      // Action sheet should appear
      expect(find.text('Switch to Artisan'), findsOneWidget);
      expect(
        find.text(
          'Create or sign in to an Artisan account to manage your crafts, products and artisan profile.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue to Artisan Login'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Multilingual rendering in Tamil and Hindi without text collision',
        (WidgetTester tester) async {
      const session = UserSession(
        isAuthenticated: true,
        activeRole: UserRole.customer,
        hasArtisanProfile: true,
      );

      // Test Tamil
      await tester.pumpWidget(createTestWidget(session: session, locale: const Locale('ta')));
      await tester.pumpAndSettle();
      expect(find.text('கைவினைஞர் அனுபவத்திற்கு மாறவும்'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test Hindi
      await tester.pumpWidget(createTestWidget(session: session, locale: const Locale('hi')));
      await tester.pumpAndSettle();
      expect(find.text('कारीगर अनुभव पर स्विच करें'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
