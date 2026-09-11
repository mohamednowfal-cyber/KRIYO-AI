import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/order_tracking_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/models/tracking_models.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/providers/tracking_provider.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/repository/tracking_repository.dart';
import 'package:kriyo_artisan_app/features/buyer/orders/tracking/screens/full_route_map_screen.dart';
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

class _FakeHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  static final List<int> _transparent1x1Png = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparent1x1Png.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparent1x1Png]).listen(
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

  group('Tracking Repository & Model Tests', () {
    test('MockTrackingRepository loads shipment with authentic NH48 Indian coordinates', () async {
      final repo = MockTrackingRepository();
      final shipment = await repo.getTracking('KRY-57866');

      expect(shipment.orderId, equals('KRY-57866'));
      expect(shipment.carrierName, equals('India Post Artisan Express'));
      expect(shipment.origin.locationName, contains('Kanchipuram'));
      expect(shipment.destination.locationName, contains('Bengaluru'));
      expect(shipment.currentStatus, equals('Out for Delivery'));
      expect(shipment.isSimulated, isTrue); // Clearly labeled demo tracking

      // Verify coordinate ranges (Kanchipuram ~12.8°N, 79.7°E to Bengaluru ~12.9°N, 77.6°E)
      expect(shipment.origin.latitude, closeTo(12.83, 0.1));
      expect(shipment.origin.longitude, closeTo(79.70, 0.1));
      expect(shipment.destination.latitude, closeTo(12.97, 0.1));
      expect(shipment.destination.longitude, closeTo(77.64, 0.1));

      // Verify route splitting: completed + remaining
      expect(shipment.completedRoute.length, greaterThan(5));
      expect(shipment.remainingRoute.length, greaterThan(1));
      expect(shipment.completedRoute.last, equals(shipment.currentLocation.toLatLng));

      // Verify logistics hubs
      expect(shipment.hubs.length, equals(5));
      expect(shipment.hubs.any((h) => h.name.contains('Bengaluru South')), isTrue);

      // Verify events contain craft heritage milestones
      expect(shipment.events.any((e) => e.isCraftMilestone && e.title.contains('Weaving')), isTrue);
      expect(shipment.events.any((e) => e.isCraftMilestone && e.title.contains('GI')), isTrue);
      expect(shipment.events.any((e) => e.isCurrent && e.title.contains('Out for Delivery')), isTrue);
    });

    test('Refresh updates timestamp and retains route integrity', () async {
      final repo = MockTrackingRepository();
      final refreshed = await repo.refreshTracking('KRY-57866');

      expect(refreshed.lastUpdated, equals('Just now'));
      expect(refreshed.orderId, equals('KRY-57866'));
      expect(refreshed.routeCoordinates.isNotEmpty, isTrue);
    });
  });

  group('Tracking Notifier Provider Tests', () {
    test('TrackingNotifier initializes, loads data, and handles refresh', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stateAsync = container.read(trackingProvider('KRY-57866'));
      expect(stateAsync.isLoading, isTrue);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 350));
      final loadedState = container.read(trackingProvider('KRY-57866'));
      expect(loadedState.isLoading, isFalse);
      expect(loadedState.shipment, isNotNull);
      expect(loadedState.shipment!.orderId, equals('KRY-57866'));

      // Test Refresh
      final notifier = container.read(trackingProvider('KRY-57866').notifier);
      final refreshFuture = notifier.refresh();
      expect(container.read(trackingProvider('KRY-57866')).isRefreshing, isTrue);
      await refreshFuture;
      expect(container.read(trackingProvider('KRY-57866')).isRefreshing, isFalse);
      expect(container.read(trackingProvider('KRY-57866')).shipment!.lastUpdated, equals('Just now'));
    });
  });

  group('Order Tracking Screen Widget Tests', () {
    testWidgets('Renders Live Tracking header, interactive map, and craft timeline', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: {'id': 'KRY-57866'}),
          ),
        ),
      );

      // Initial loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Header
      expect(find.text('Live Tracking #KRY-57866'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsWidgets);
      expect(find.textContaining('Expected Today'), findsWidgets);
      expect(find.text('Demo Tracking'), findsOneWidget);

      // Verify Real Map Widget is rendered
      expect(find.byType(TrackingMapWidget), findsOneWidget);
      expect(find.text('Full Route Map'), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget); // Recenter control

      // Verify Timeline section
      expect(find.text('Tracking Timeline'), findsOneWidget);
      expect(find.text('CRAFT & TRANSIT'), findsOneWidget);

      // Verify Craft Milestones
      expect(find.text('Craft Weaving Completed by Lakshmi Devi'), findsOneWidget);
      expect(find.text('GI Authenticity Stamp & Quality Passed'), findsOneWidget);
      expect(find.text('Dispatched from Kanchipuram Artisan Guild'), findsOneWidget);
      expect(find.text('Arrived at Bengaluru Transit Facility'), findsOneWidget);
      expect(find.text('Out for Delivery by Courier Partner'), findsOneWidget);
      expect(find.text('CRAFT'), findsWidgets); // Craft milestone tags
    });

    testWidgets('Full Route Map Screen renders full screen map and driver summary card', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FullRouteMapScreen(orderId: 'KRY-57866'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Full Route Map #KRY-57866'), findsOneWidget);
      expect(find.byType(TrackingMapWidget), findsOneWidget);
      expect(find.textContaining('Rajesh Kumar'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('On-map controls: zoom in, zoom out, and recenter are displayed', (tester) async {
      final repo = MockTrackingRepository();
      final shipment = await repo.getTracking('KRY-57866');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: TrackingMapWidget(shipment: shipment),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    });
  });
}
