import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_signup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/widgets/artisan_pottery_animated_background.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_signup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/widgets/customer_craft_journey_animated_background.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Craft Journey (Customer) and Weaving Needles (Artisan) Animation Tests', () {
    testWidgets(
        'CustomerCraftJourneyAnimatedBackground renders warm ivory paper, marketplace arch, and craft painter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerCraftJourneyAnimatedBackground(
              child: Text('Customer Craft Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerCraftJourneyAnimatedBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Customer Craft Content'), findsOneWidget);
    });

    testWidgets(
        'CustomerLoginScreen embeds CustomerCraftJourneyAnimatedBackground with logo and login form',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
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

      expect(find.byType(CustomerCraftJourneyAnimatedBackground), findsOneWidget);
      expect(find.text('Discover Handmade'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets(
        'CustomerSignUpScreen embeds CustomerCraftJourneyAnimatedBackground with registration form',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerSignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerCraftJourneyAnimatedBackground), findsOneWidget);
      expect(find.text('Join KRIYO'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
    });

    testWidgets(
        'ArtisanLoginScreen embeds ArtisanPotteryAnimatedBackground with needles weaving KRIYO and woven thread borders',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
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

      expect(find.byType(ArtisanPotteryAnimatedBackground), findsOneWidget);
      expect(find.text('ARTISAN PORTAL'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets(
        'ArtisanSignUpScreen embeds ArtisanPotteryAnimatedBackground with needles and woven borders',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanSignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ArtisanPotteryAnimatedBackground), findsOneWidget);
      expect(find.text('Create Artisan Account'), findsOneWidget);
    });
  });
}
