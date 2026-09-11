import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/constants/asset_constants.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_signup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_welcome_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/presentation/widgets/auth_logo.dart';
import 'package:kriyo_artisan_app/features/language/presentation/screens/language_selection_screen.dart';
import 'package:kriyo_artisan_app/features/role_selection/presentation/screens/role_selection_screen.dart';
import 'package:kriyo_artisan_app/features/splash/presentation/screens/splash_screen.dart';

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

  group('KRIYO Logo Path & Rendering Consistency Tests', () {
    test('All logo asset constants point to assets/images/kriyo_logo.png', () {
      expect(AssetConstants.logo, 'assets/images/kriyo_logo.png');
      expect(AssetConstants.logoJpg, 'assets/images/kriyo_logo.png');
      expect(AssetConstants.kriyoLogo, 'assets/images/kriyo_logo.png');
    });

    testWidgets('AuthLogo renders Image.asset with assets/images/kriyo_logo.png',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthLogo(width: 180),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image image = tester.widget(imageFinder);
      expect(image.image, isA<AssetImage>());
      final AssetImage assetImage = image.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/kriyo_logo.png');
    });

    testWidgets('SplashScreen contains kriyo_logo.png', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );
      await tester.pump();

      final images = tester.widgetList<Image>(find.byType(Image));
      final hasKriyoLogo = images.any((img) =>
          img.image is AssetImage &&
          (img.image as AssetImage).assetName == 'assets/images/kriyo_logo.png');
      expect(hasKriyoLogo, isTrue);
    });

    testWidgets('LanguageSelectionScreen features kriyo_logo.png header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LanguageSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final images = tester.widgetList<Image>(find.byType(Image));
      final hasKriyoLogo = images.any((img) =>
          img.image is AssetImage &&
          (img.image as AssetImage).assetName == 'assets/images/kriyo_logo.png');
      expect(hasKriyoLogo, isTrue);
    });

    testWidgets('RoleSelectionScreen features AuthLogo with kriyo_logo.png', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RoleSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthLogo), findsOneWidget);
      final Image image = tester.widget(find.descendant(
        of: find.byType(AuthLogo),
        matching: find.byType(Image),
      ));
      expect((image.image as AssetImage).assetName, 'assets/images/kriyo_logo.png');
    });

    testWidgets('CustomerLoginScreen features AuthLogo with kriyo_logo.png', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthLogo), findsOneWidget);
      final Image image = tester.widget(find.descendant(
        of: find.byType(AuthLogo),
        matching: find.byType(Image),
      ));
      expect((image.image as AssetImage).assetName, 'assets/images/kriyo_logo.png');
    });

    testWidgets('CustomerSignUpScreen features AuthLogo with kriyo_logo.png', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerSignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthLogo), findsOneWidget);
      final Image image = tester.widget(find.descendant(
        of: find.byType(AuthLogo),
        matching: find.byType(Image),
      ));
      expect((image.image as AssetImage).assetName, 'assets/images/kriyo_logo.png');
    });

    testWidgets('CustomerWelcomeScreen features AuthLogo with kriyo_logo.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerWelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthLogo), findsOneWidget);
      final Image image = tester.widget(find.descendant(
        of: find.byType(AuthLogo),
        matching: find.byType(Image),
      ));
      expect((image.image as AssetImage).assetName, 'assets/images/kriyo_logo.png');
    });
  });
}
