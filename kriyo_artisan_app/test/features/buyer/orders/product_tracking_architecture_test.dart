import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/customer_order_details_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/order_tracking_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/models/tracking_models.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/providers/tracking_provider.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/repository/tracking_repository.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/widgets/tracking_map_widget.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeHttpRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('Multi-Product Order #KRY-10248 Data Architecture', () {
    test('Order #KRY-10248 contains two distinct products with unique tracking IDs and prices', () {
      final order = UserSession.defaultOrders.firstWhere(
        (o) => o.orderNumber == 'KRY-10248',
      );

      expect(order.items.length, equals(2));
      expect(order.total, equals(16400));

      final item1 = order.items[0];
      final item2 = order.items[1];

      // Product 1: Kanchipuram Silk Saree
      expect(item1.effectiveItemId, equals('KRY-10248-01'));
      expect(item1.title, contains('Kanchipuram'));
      expect(item1.artisanName, equals('Lakshmi Devi'));
      expect(item1.price, equals(14550));
      expect(item1.effectiveTrackingId, equals('IP98492101'));
      expect(item1.effectiveStatus, equals('Out for Delivery'));

      // Product 2: Terracotta Sound Bowl
      expect(item2.effectiveItemId, equals('KRY-10248-02'));
      expect(item2.title, contains('Terracotta'));
      expect(item2.artisanName, equals('Murugesan Perumal'));
      expect(item2.price, equals(1850));
      expect(item2.effectiveTrackingId, equals('IP98492102'));
      expect(item2.effectiveStatus, equals('In Transit'));

      // Verify no shared fake duplicate data
      expect(item1.effectiveTrackingId, isNot(equals(item2.effectiveTrackingId)));
      expect(item1.artisanName, isNot(equals(item2.artisanName)));
      expect(item1.price, isNot(equals(item2.price)));
    });
  });

  group('Tracking Repository Product Separation Tests', () {
    final repo = MockTrackingRepository();

    test('Loads distinct tracking for Saree (Product 1) vs Terracotta Bowl (Product 2)', () async {
      // Fetch Product 1 (Saree)
      final sareeTracking = await repo.getTracking(
        'KRY-10248',
        orderItemId: 'item_10248_1',
        productId: 'p1',
      );

      // Fetch Product 2 (Terracotta Bowl)
      final bowlTracking = await repo.getTracking(
        'KRY-10248',
        orderItemId: 'item_10248_2',
        productId: 'p2',
      );

      // Verify Saree Details
      expect(sareeTracking.productName, contains('Kanchipuram'));
      expect(sareeTracking.artisanName, equals('Lakshmi Devi'));
      expect(sareeTracking.trackingNumber, equals('IP98492101'));
      expect(sareeTracking.currentStatus, equals('Out for Delivery'));
      expect(sareeTracking.origin.locationName, contains('Kanchipuram'));
      expect(sareeTracking.driverName, equals('Rajesh Kumar'));
      expect(sareeTracking.unitPrice, equals(14550.0));

      // Verify Terracotta Bowl Details
      expect(bowlTracking.productName, contains('Terracotta'));
      expect(bowlTracking.artisanName, equals('Murugesan Perumal'));
      expect(bowlTracking.trackingNumber, equals('IP98492102'));
      expect(bowlTracking.currentStatus, equals('In Transit'));
      expect(bowlTracking.origin.locationName, contains('Villianur'));
      expect(bowlTracking.driverName, equals('Suresh Babu'));
      expect(bowlTracking.unitPrice, equals(1850.0));

      // Verify Route separation (Coordinates and Hubs are completely distinct)
      expect(sareeTracking.origin.latitude, isNot(equals(bowlTracking.origin.latitude)));
      expect(sareeTracking.routeCoordinates.first, isNot(equals(bowlTracking.routeCoordinates.first)));
      expect(sareeTracking.hubs.first.name, contains('Kanchipuram'));
      expect(bowlTracking.hubs.first.name, contains('Villianur'));
    });

    test('Refresh tracking updates timestamp without mutating product identity', () async {
      final refreshed = await repo.refreshTracking(
        'KRY-10248',
        orderItemId: 'item_10248_2',
        productId: 'p2',
      );

      expect(refreshed.lastUpdated, equals('Just now'));
      expect(refreshed.productName, contains('Terracotta'));
      expect(refreshed.artisanName, equals('Murugesan Perumal'));
    });
  });

  group('Customer Order Details Screen Multi-Product Tests', () {
    testWidgets('Renders each product individually with title, artisan, price calculation and Track Package button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerOrderDetailsScreen(orderId: 'KRY-10248'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Order Header
      expect(find.text('Order #KRY-10248'), findsOneWidget);
      expect(find.text('2 Products'), findsOneWidget);

      // Verify Product 1 is rendered
      expect(find.textContaining('Kanchipuram'), findsWidgets);
      expect(find.textContaining('Lakshmi Devi'), findsWidgets);
      expect(find.text('₹14550 × 1 = ₹14550'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsWidgets);

      // Verify Product 2 is rendered
      expect(find.textContaining('Terracotta'), findsWidgets);
      expect(find.textContaining('Murugesan Perumal'), findsWidgets);
      expect(find.text('₹1850 × 1 = ₹1850'), findsOneWidget);
      expect(find.text('In Transit'), findsWidgets);

      // Verify individual Track Package buttons exist for each item
      final trackPackageButtons = find.widgetWithText(ElevatedButton, 'Track Package');
      expect(trackPackageButtons, findsNWidgets(2));
    });
  });

  group('Live Order Tracking Screen Tests', () {
    testWidgets('Renders product identity card, map, and timeline for Product 1', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(
              orderId: 'KRY-10248',
              orderItemId: 'item_10248_1',
              productId: 'p1',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Header
      expect(find.text('Live Tracking #KRY-10248'), findsOneWidget);
      expect(find.textContaining('IP98492101'), findsWidgets);
      expect(find.text('LIVE'), findsOneWidget);

      // Product Identity Card
      expect(find.textContaining('Kanchipuram Pure Mulberry Silk Saree'), findsOneWidget);
      expect(find.textContaining('Lakshmi Devi'), findsWidgets);

      // Map Widget
      expect(find.byType(TrackingMapWidget), findsOneWidget);

      // Timeline
      expect(find.text('Tracking Timeline'), findsOneWidget);
      expect(find.text('CRAFT & TRANSIT'), findsOneWidget);
      expect(find.textContaining('Out for Delivery'), findsWidgets);
    });

    testWidgets('Renders product identity card, map, and timeline for Product 2', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(
              orderId: 'KRY-10248',
              orderItemId: 'item_10248_2',
              productId: 'p2',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Header
      expect(find.text('Live Tracking #KRY-10248'), findsOneWidget);
      expect(find.textContaining('IP98492102'), findsWidgets);
      expect(find.text('LIVE'), findsOneWidget);

      // Product Identity Card
      expect(find.textContaining('Villianur Handcrafted Terracotta Sound Bowl'), findsOneWidget);
      expect(find.textContaining('Murugesan Perumal'), findsWidgets);

      // Map Widget
      expect(find.byType(TrackingMapWidget), findsOneWidget);

      // Timeline
      expect(find.text('Tracking Timeline'), findsOneWidget);
      expect(find.textContaining('In Transit'), findsWidgets);
      expect(find.textContaining('Krishnagiri'), findsWidgets);
    });
  });
}
