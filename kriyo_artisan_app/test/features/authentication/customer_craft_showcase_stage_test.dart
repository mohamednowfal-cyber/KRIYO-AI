import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_signup_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/widgets/customer_craft_journey_animated_background.dart';
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

  group('Customer Craft Showcase Stage & Scrolling Behavior Tests', () {
    testWidgets(
        'CustomerCraftShowcaseStage renders with CustomPaint without errors',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerCraftShowcaseStage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerCraftShowcaseStage), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
        'CustomerLoginScreen places CustomerCraftShowcaseStage directly below AuthLogo and moves upwards on scroll',
        (tester) async {
      tester.view.physicalSize = const Size(400, 700);
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

      // Verify AuthLogo and CustomerCraftShowcaseStage presence
      final logoFinder = find.byType(AuthLogo);
      final craftStageFinder = find.byType(CustomerCraftShowcaseStage);

      expect(logoFinder, findsOneWidget);
      expect(craftStageFinder, findsOneWidget);

      final logoOffsetBefore = tester.getTopLeft(logoFinder);
      final craftOffsetBefore = tester.getTopLeft(craftStageFinder);

      // Verify craft stage is strictly BELOW the logo
      expect(craftOffsetBefore.dy, greaterThan(logoOffsetBefore.dy));

      // Scroll the SingleChildScrollView upwards
      final scrollableFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollableFinder, const Offset(0, -200));
      await tester.pumpAndSettle();

      final craftOffsetAfter = tester.getTopLeft(craftStageFinder);

      // Verify that when scrolling, the craft products stage moves upwards!
      expect(craftOffsetAfter.dy, lessThan(craftOffsetBefore.dy));
    });

    testWidgets(
        'CustomerSignUpScreen places CustomerCraftShowcaseStage directly below AuthLogo and moves upwards on scroll',
        (tester) async {
      tester.view.physicalSize = const Size(400, 700);
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

      final logoFinder = find.byType(AuthLogo);
      final craftStageFinder = find.byType(CustomerCraftShowcaseStage);

      expect(logoFinder, findsOneWidget);
      expect(craftStageFinder, findsOneWidget);

      final logoOffsetBefore = tester.getTopLeft(logoFinder);
      final craftOffsetBefore = tester.getTopLeft(craftStageFinder);

      // Verify craft stage is strictly BELOW the logo
      expect(craftOffsetBefore.dy, greaterThan(logoOffsetBefore.dy));

      // Scroll the SingleChildScrollView upwards
      final scrollableFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollableFinder, const Offset(0, -200));
      await tester.pumpAndSettle();

      final craftOffsetAfter = tester.getTopLeft(craftStageFinder);

      // Verify that when scrolling, the craft products stage moves upwards!
      expect(craftOffsetAfter.dy, lessThan(craftOffsetBefore.dy));
    });
  });
}
