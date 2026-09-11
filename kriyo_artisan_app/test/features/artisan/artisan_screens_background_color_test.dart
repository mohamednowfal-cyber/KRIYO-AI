import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/theme/app_colors.dart';
import 'package:kriyo_artisan_app/app/theme/app_theme.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_signup_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/home/artisan_navigation_wrapper.dart';
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

  group('Artisan Screens Background Color Specifications', () {
    test('artisanBackground color token is exactly #FFFFFF', () {
      expect(AppColors.artisanBackground, const Color(0xFFFFFFFF));
    });

    test('artisanTheme scaffoldBackgroundColor and canvasColor are #FFFFFF', () {
      expect(AppTheme.artisanTheme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
      expect(AppTheme.artisanTheme.canvasColor, const Color(0xFFFFFFFF));
      expect(AppTheme.artisanTheme.appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    });

    testWidgets('ArtisanLoginScreen retains AppColors.warmIvory background (excluded from #FFFFFF)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.warmIvory);
      expect(scaffold.backgroundColor, isNot(AppColors.artisanBackground));
    });

    testWidgets('ArtisanSignUpScreen retains AppColors.warmIvory background (excluded from #FFFFFF)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanSignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.warmIvory);
      expect(scaffold.backgroundColor, isNot(AppColors.artisanBackground));
    });

    testWidgets('ArtisanNavigationWrapper has #FFFFFF background color',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanNavigationWrapper(),
          ),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
    });
  });
}
