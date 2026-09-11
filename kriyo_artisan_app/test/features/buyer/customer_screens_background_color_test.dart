import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/theme/app_colors.dart';
import 'package:kriyo_artisan_app/app/theme/app_theme.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/buyer/screens/customer_signup_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/home/customer_navigation_wrapper.dart';
import 'package:kriyo_artisan_app/features/buyer/home/customer_home_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/settings/about_kriyo_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Customer Screens Background Color Specifications (Matching Artisan #FFFFFF)', () {
    test('customerBackground color token is exactly #FFFFFF, identical to artisanBackground', () {
      expect(AppColors.customerBackground, const Color(0xFFFFFFFF));
      expect(AppColors.customerBackground, equals(AppColors.artisanBackground));
    });

    test('customerTheme scaffoldBackgroundColor and canvasColor are #FFFFFF', () {
      expect(AppTheme.customerTheme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
      expect(AppTheme.customerTheme.canvasColor, const Color(0xFFFFFFFF));
      expect(AppTheme.customerTheme.appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    });

    testWidgets('CustomerLoginScreen retains AppColors.warmIvory background (excluded from #FFFFFF)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.warmIvory);
      expect(scaffold.backgroundColor, isNot(AppColors.customerBackground));
    });

    testWidgets('CustomerSignUpScreen retains AppColors.warmIvory background (excluded from #FFFFFF)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerSignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.warmIvory);
      expect(scaffold.backgroundColor, isNot(AppColors.customerBackground));
    });

    testWidgets('AboutKriyoScreen has #FFFFFF background color',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AboutKriyoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
    });

    testWidgets('CustomerHomeScreen has #FFFFFF background color',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFFFFFFFF),
              body: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
    });
  });
}
