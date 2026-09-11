import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/shared/widgets/kriyo_bottom_navigation.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) => _FakeHttpClientResponse();
}

class _FakeHttpClientResponse implements HttpClientResponse {
  static final List<int> _transparentPng = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Artisan navigation displays Create label and localizes across languages', (tester) async {
    // 1. English Artisan navigation
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              bottomNavigationBar: KriyoBottomNavigation(
                role: KriyoNavRole.artisan,
                currentIndex: 0,
                customItems: [
                  KriyoNavigationItem(
                    label: l10n?.home ?? 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.craft ?? 'Craft',
                    icon: Icons.handyman_outlined,
                    activeIcon: Icons.handyman_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.create ?? 'Create',
                    icon: Icons.add_rounded,
                    activeIcon: Icons.add_rounded,
                    isPrimaryAction: true,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.orders ?? 'Orders',
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.profile ?? 'Profile',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ],
                onTabChanged: (_) {},
              ),
            );
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Craft'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify center icon is '+'
    expect(find.byIcon(Icons.add_rounded), findsWidgets);

    // 2. Tamil Artisan navigation
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ta'),
          home: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              bottomNavigationBar: KriyoBottomNavigation(
                role: KriyoNavRole.artisan,
                currentIndex: 0,
                customItems: [
                  KriyoNavigationItem(
                    label: l10n?.home ?? 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.craft ?? 'Craft',
                    icon: Icons.handyman_outlined,
                    activeIcon: Icons.handyman_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.create ?? 'Create',
                    icon: Icons.add_rounded,
                    activeIcon: Icons.add_rounded,
                    isPrimaryAction: true,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.orders ?? 'Orders',
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.profile ?? 'Profile',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ],
                onTabChanged: (_) {},
              ),
            );
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('முகப்பு'), findsOneWidget);
    expect(find.text('கைவினை'), findsOneWidget);
    expect(find.text('உருவாக்கு'), findsOneWidget);
    expect(find.text('ஆர்டர்கள்'), findsOneWidget);
    expect(find.text('சுயவிவரம்'), findsOneWidget);

    // 3. Hindi Artisan navigation
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('hi'),
          home: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              bottomNavigationBar: KriyoBottomNavigation(
                role: KriyoNavRole.artisan,
                currentIndex: 0,
                customItems: [
                  KriyoNavigationItem(
                    label: l10n?.home ?? 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.craft ?? 'Craft',
                    icon: Icons.handyman_outlined,
                    activeIcon: Icons.handyman_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.create ?? 'Create',
                    icon: Icons.add_rounded,
                    activeIcon: Icons.add_rounded,
                    isPrimaryAction: true,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.orders ?? 'Orders',
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.profile ?? 'Profile',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ],
                onTabChanged: (_) {},
              ),
            );
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('होम'), findsOneWidget);
    expect(find.text('शिल्प'), findsOneWidget);
    expect(find.text('बनाएँ'), findsOneWidget);
    expect(find.text('ऑर्डर'), findsOneWidget);
    expect(find.text('प्रोफ़ाइल'), findsOneWidget);
  });

  testWidgets('Customer navigation displays Home, Explore, Wishlist, Cart, Me without Create', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              bottomNavigationBar: KriyoBottomNavigation(
                role: KriyoNavRole.customer,
                currentIndex: 0,
                customItems: [
                  KriyoNavigationItem(
                    label: l10n?.home ?? 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.explore ?? 'Explore',
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.wishlist ?? 'Wishlist',
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.cart ?? 'Cart',
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag_rounded,
                  ),
                  KriyoNavigationItem(
                    label: l10n?.me ?? 'Me',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ],
                onTabChanged: (_) {},
              ),
            );
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    // Ensure Create is NOT present in Customer navigation
    expect(find.text('Create'), findsNothing);
  });
}
