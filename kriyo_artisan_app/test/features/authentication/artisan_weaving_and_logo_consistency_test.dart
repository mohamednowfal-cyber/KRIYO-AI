import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/constants/asset_constants.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_signup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/widgets/artisan_pottery_animated_background.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/presentation/widgets/auth_logo.dart';

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

  group('Artisan Weaving & Top Logo Consistency Tests', () {
    testWidgets(
        'ArtisanLoginScreen has AuthLogo at top center identical to CustomerLoginScreen',
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

      // 1. Verify AuthLogo is rendered
      final logoFinder = find.byType(AuthLogo);
      expect(logoFinder, findsOneWidget);

      final authLogo = tester.widget<AuthLogo>(logoFinder);
      expect(authLogo.width, 170);
      expect(authLogo.showTagline, isFalse);

      // 2. Verify ARTISAN PORTAL badge in AppBar
      expect(find.text('ARTISAN PORTAL'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 3. Verify Form title & inputs
      expect(find.text('Welcome back, Artisan'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // 4. Verify background image is removed (only AuthLogo image is present, no artisanWeavingBg)
      expect(find.byType(ArtisanPotteryAnimatedBackground), findsOneWidget);
      final images = tester.widgetList<Image>(find.byType(Image));
      final hasBg = images.any((img) => img.image is AssetImage && (img.image as AssetImage).assetName == AssetConstants.artisanWeavingBg);
      expect(hasBg, isFalse);
    });

    testWidgets(
        'ArtisanSignUpScreen has AuthLogo at top center and background image is removed',
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

      // 1. Verify AuthLogo is rendered
      final logoFinder = find.byType(AuthLogo);
      expect(logoFinder, findsOneWidget);

      final authLogo = tester.widget<AuthLogo>(logoFinder);
      expect(authLogo.width, 170);
      expect(authLogo.showTagline, isFalse);

      // 2. Verify ARTISAN SIGN UP badge in AppBar
      expect(find.text('ARTISAN SIGN UP'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 3. Verify Form fields
      expect(find.text('Create Your Artisan Identity'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Create Artisan Account'), findsOneWidget);

      // 4. Verify background image is removed
      final images = tester.widgetList<Image>(find.byType(Image));
      final hasBg = images.any((img) => img.image is AssetImage && (img.image as AssetImage).assetName == AssetConstants.artisanWeavingBg);
      expect(hasBg, isFalse);
    });
  });
}
