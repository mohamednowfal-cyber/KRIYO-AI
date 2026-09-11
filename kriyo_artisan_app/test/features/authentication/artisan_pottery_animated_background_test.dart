import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/constants/asset_constants.dart';
import 'package:kriyo_artisan_app/app/theme/app_colors.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_signup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/widgets/artisan_pottery_animated_background.dart';

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

  group('Artisan Weaving Animated Background Specifications', () {
    test('artisanWeavingBg asset constant points to assets/images/artisan_weaving_bg.jpg', () {
      expect(AssetConstants.artisanWeavingBg, 'assets/images/artisan_weaving_bg.jpg');
    });

    testWidgets('ArtisanPotteryAnimatedBackground renders clean warm ivory canvas and CustomPaint without background image',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtisanPotteryAnimatedBackground(
              child: Text('Artisan Weaving Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify widget hierarchy
      expect(find.byType(ArtisanPotteryAnimatedBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Artisan Weaving Content'), findsOneWidget);
      // Background image is removed, so no background Image widget in ArtisanPotteryAnimatedBackground
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('ArtisanLoginScreen embeds ArtisanPotteryAnimatedBackground with full interactive form and AuthLogo',
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

      // 1. Verify animated weaving background is present
      expect(find.byType(ArtisanPotteryAnimatedBackground), findsOneWidget);

      // 2. Verify header portal badge and back button
      expect(find.text('ARTISAN PORTAL'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 3. Verify form typography and inputs
      expect(find.text('Welcome back, Artisan'), findsOneWidget);
      expect(find.text('Continue your craft journey with KRIYO.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Create Artisan Account'), findsOneWidget);

      // 4. Test typing and interaction
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pumpAndSettle();
      expect(find.text('9876543210'), findsOneWidget);

      // 5. Test tap on background triggers ripple
      await tester.tap(find.byType(ArtisanPotteryAnimatedBackground));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ArtisanSignUpScreen embeds ArtisanPotteryAnimatedBackground with full registration fields',
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

      // 1. Verify animated pottery background is present
      expect(find.byType(ArtisanPotteryAnimatedBackground), findsOneWidget);

      // 2. Verify header badge
      expect(find.text('ARTISAN SIGN UP'), findsOneWidget);

      // 3. Verify title and craft fields
      expect(find.text('Create Your Artisan Identity'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Primary Craft'), findsOneWidget);
      expect(find.text('Clay Pottery & Terracotta'), findsOneWidget);
      expect(find.text('Create Artisan Account'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
