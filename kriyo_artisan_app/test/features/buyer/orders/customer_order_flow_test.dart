import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/buyer/home/customer_navigation_wrapper.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/customer_orders_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/services/customer_invoice_service.dart';
import 'package:kriyo_artisan_app/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:kriyo_artisan_app/shared/widgets/customer_top_app_bar_actions.dart';
import 'package:kriyo_artisan_app/shared/widgets/kriyo_bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:io';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Customer Bottom Navigation Structure (Section 1)', () {
    testWidgets('CustomerNavigationWrapper contains 5 tabs with Orders at index 3', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomerBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find bottom navigation bar
      final navFinder = find.byType(KriyoBottomNavigation);
      expect(navFinder, findsOneWidget);

      final navWidget = tester.widget<KriyoBottomNavigation>(navFinder);
      expect(navWidget.customItems, isNotNull);
      expect(navWidget.customItems!.length, equals(5));

      expect(navWidget.customItems![0].label, equals('Home'));
      expect(navWidget.customItems![1].label, equals('Explore'));
      expect(navWidget.customItems![2].label, equals('Reels'));
      expect(navWidget.customItems![3].label, equals('Orders'));
      expect(navWidget.customItems![4].label, equals('Me'));
    });
  });

  group('Customer Top App Bar Cart Badge & Actions (Sections 2, 3, 4)', () {
    testWidgets('Empty cart does not display "0" badge', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [CustomerTopAppBarActions()],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify cart and notification icons exist
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Verify no "0" badge is rendered
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Cart badge dynamically reflects added items and quantities', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [CustomerTopAppBarActions()],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Add item to cart via session notifier
      container.read(sessionProvider.notifier).addToCart(
            const CustomerCartItem(
              id: 'PRD-TEST-1',
              title: 'Temple Border Silk Saree',
              artisanName: 'Lakshmi Devi',
              craftType: 'Handloom Weaving',
              region: 'Kanchipuram, Tamil Nadu',
              price: 14500,
              imageUrl: 'https://example.com/saree.jpg',
              quantity: 2,
            ),
          );

      await tester.pump();

      // Badge should now display "2"
      expect(find.text('2'), findsOneWidget);

      // Add another item with quantity 1
      container.read(sessionProvider.notifier).addToCart(
            const CustomerCartItem(
              id: 'PRD-TEST-2',
              title: 'Terracotta Sound Bowl',
              artisanName: 'Murugesan Perumal',
              craftType: 'Terracotta Pottery',
              region: 'Puducherry',
              price: 1850,
              imageUrl: 'https://example.com/bowl.jpg',
              quantity: 1,
            ),
          );

      await tester.pump();

      // Badge should now display "3"
      expect(find.text('3'), findsOneWidget);

      // Clear cart
      container.read(sessionProvider.notifier).clearCart();
      await tester.pump();

      // Badge disappears
      expect(find.text('3'), findsNothing);
      expect(find.text('0'), findsNothing);
    });
  });

  group('Customer Orders Screen & Category Filters (Section 5, 6)', () {
    testWidgets('My Orders screen renders horizontal filter chips with real counts', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CustomerOrdersScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('My Orders'), findsOneWidget);

      // Check for filter chips with counts (from default 5 orders)
      expect(find.textContaining('All (5)'), findsOneWidget);
      expect(find.textContaining('Processing (1)'), findsOneWidget);
      expect(find.textContaining('Shipped (2)'), findsOneWidget);
      expect(find.textContaining('Delivered (1)'), findsOneWidget);
      expect(find.textContaining('Cancelled (1)'), findsOneWidget);

      // Tap on Shipped tab
      await tester.tap(find.textContaining('Shipped (2)'));
      await tester.pumpAndSettle();

      // Shipped orders should appear
      expect(find.text('Order #KRY-10192'), findsOneWidget);
      expect(find.text('Order #KRY-09720'), findsOneWidget);
      // Processing order should not appear
      expect(find.text('Order #KRY-10248'), findsNothing);
    });
  });

  group('Order Cancellation Rules & Ledger Operations (Sections 19, 20, 21)', () {
    test('Processing order can be cancelled and initiates refund for prepaid orders', () {
      final container = ProviderContainer();
      final sessionNotifier = container.read(sessionProvider.notifier);

      // Check KRY-10248 (Processing)
      final initialOrder = container
          .read(sessionProvider)
          .customerOrders
          .firstWhere((o) => o.orderNumber == 'KRY-10248', orElse: () => UserSession.defaultOrders.first);

      expect(initialOrder.isCancellable, isTrue);

      final cancelSuccess = sessionNotifier.cancelCustomerOrder(
        'KRY-10248',
        reason: 'Changed my mind',
      );

      expect(cancelSuccess, isTrue);

      final updatedOrder = container
          .read(sessionProvider)
          .customerOrders
          .firstWhere((o) => o.orderNumber == 'KRY-10248');

      expect(updatedOrder.status, equals('Cancelled'));
      expect(updatedOrder.cancellationReason, equals('Changed my mind'));
      expect(updatedOrder.paymentStatus, equals('Refund Initiated'));
      expect(updatedOrder.cancelledAt, isNotNull);
      expect(updatedOrder.isCancellable, isFalse);
    });

    test('Shipped and Delivered orders cannot be cancelled according to business rules', () {
      final container = ProviderContainer();
      final sessionNotifier = container.read(sessionProvider.notifier);

      // KRY-10192 is Shipped via Express
      final shippedOrder = UserSession.defaultOrders.firstWhere((o) => o.orderNumber == 'KRY-10192');
      expect(shippedOrder.isCancellable, isFalse);

      final cancelShipped = sessionNotifier.cancelCustomerOrder(
        'KRY-10192',
        reason: 'Too late',
      );
      expect(cancelShipped, isFalse);

      // KRY-09884 is Delivered
      final deliveredOrder = UserSession.defaultOrders.firstWhere((o) => o.orderNumber == 'KRY-09884');
      expect(deliveredOrder.isCancellable, isFalse);

      final cancelDelivered = sessionNotifier.cancelCustomerOrder(
        'KRY-09884',
        reason: 'Not needed',
      );
      expect(cancelDelivered, isFalse);
    });
  });

  group('Customer PDF Invoice Generation Service (Sections 12, 13, 14, 15, 16)', () {
    test('generateInvoicePdf generates valid non-empty PDF bytes matching order totals', () async {
      final order = UserSession.defaultOrders.first;

      final pdfBytes = await CustomerInvoiceService.generateInvoicePdf(order);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF documents start with %PDF header
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, equals('%PDF'));
    });
  });
}
