import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/explore_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/explore/widgets/explore_search_bar.dart';
import 'package:kriyo_artisan_app/features/buyer/payment/customer_payment_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/products/product_details_screen.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  Widget buildTestableApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('1. Explore Search Bar Layout & Overlap Fix Tests', () {
    testWidgets('Search bar renders single container without duplicate/inherited borders', (tester) async {
      String currentQuery = '';
      bool filterTapped = false;

      final controller = TextEditingController();
      await tester.pumpWidget(
        buildTestableApp(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ExploreSearchBar(
              controller: controller,
              onClear: () {
                controller.clear();
                currentQuery = '';
              },
              activeFilterCount: 0,
              onChanged: (q) => currentQuery = q,
              onFilterTap: () => filterTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search icon is present
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Verify hint text is present
      expect(find.text('Discover by craft, artisan, or cluster...'), findsOneWidget);

      // Verify filter icon is present inside the search bar
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Verify TextField input decoration explicitly disables duplicate borders
      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration;
      expect(decoration?.border, InputBorder.none);
      expect(decoration?.enabledBorder, InputBorder.none);
      expect(decoration?.focusedBorder, InputBorder.none);
      expect(decoration?.filled, false);

      // Verify typing triggers onChanged and shows clear button
      await tester.enterText(find.byType(TextField), 'saree');
      await tester.pump();
      expect(currentQuery, 'saree');
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pump();
      expect(currentQuery, '');

      // Verify filter button tap
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();
      expect(filterTapped, true);
    });

    testWidgets('Explore screen search filtering works dynamically', (tester) async {
      await tester.pumpWidget(
        buildTestableApp(
          child: const ExploreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial product cards exist
      expect(find.byType(ExploreSearchBar), findsOneWidget);
      expect(find.text('Handspun Kanchipuram Pure Silk Saree'), findsOneWidget);

      // Type a query that matches Saree
      await tester.enterText(find.byType(TextField), 'saree');
      await tester.pumpAndSettle();

      expect(find.text('Handspun Kanchipuram Pure Silk Saree'), findsOneWidget);

      // Type non-existent query
      await tester.enterText(find.byType(TextField), 'xyznonexistentcraft999');
      await tester.pumpAndSettle();

      expect(find.text('No Crafts Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search button to reset
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Handspun Kanchipuram Pure Silk Saree'), findsOneWidget);
    });
  });

  group('2. Product Details Dynamic Resolution Tests', () {
    testWidgets('ProductDetailsScreen resolves dynamically by productId without hardcoding', (tester) async {
      // Test with Terracotta Bowl product ID
      await tester.pumpWidget(
        buildTestableApp(
          child: const ProductDetailsScreen(
            productId: 'KRY-PRD-02',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display Terracotta Bowl data dynamically from mock catalog
      expect(find.text('Terracotta Acoustic Sound Bowl & Planter'), findsOneWidget);
      expect(find.text('Murugesan Perumal'), findsOneWidget);
      expect(find.text('Auroville Craft Enclave'), findsOneWidget);
      expect(find.textContaining('1850'), findsWidgets);

      // Should NOT display Kanchipuram Saree data
      expect(find.text('Handspun Kanchipuram Pure Silk Saree'), findsNothing);
    });

    testWidgets('ProductDetailsScreen resolves Walnut Heritage Box correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableApp(
          child: const ProductDetailsScreen(
            productId: 'KRY-PRD-03',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hand-Carved Walnut Wood Heritage Box'), findsOneWidget);
      expect(find.text('Bashir Ahmad Reshi'), findsOneWidget);
      expect(find.textContaining('4950'), findsWidgets);
    });
  });

  group('3. Add to Cart & Buy Now Flow Tests', () {
    testWidgets('Add to Cart adds item to user session cart and shows animated banner', (tester) async {
      final container = ProviderContainer();
      final sareeProduct = MockBuyerData.products.firstWhere((p) => p.id == 'KRY-PRD-01');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ProductDetailsScreen(
                product: sareeProduct,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Add to Cart button
      final addToCartFinder = find.widgetWithText(OutlinedButton, 'Add to Cart');
      expect(addToCartFinder, findsOneWidget);

      await tester.tap(addToCartFinder);
      await tester.pump();

      // Verify animated cart banner appears with VIEW CART button
      expect(find.text('Added ${sareeProduct.title} to Cart!'), findsOneWidget);
      expect(find.text('VIEW CART'), findsOneWidget);

      // Verify item was added to session cart
      final cart = container.read(sessionProvider).customerCart;
      expect(cart.isNotEmpty, true);
      expect(cart.any((i) => i.id == 'KRY-PRD-01'), true);
    });

    testWidgets('Buy Now computes unitPrice * quantity and routes to payment', (tester) async {
      final container = ProviderContainer();
      final sareeProduct = MockBuyerData.products.firstWhere((p) => p.id == 'KRY-PRD-01');

      // Setup GoRouter to test navigation
      final router = GoRouter(
        initialLocation: '/details',
        routes: [
          GoRoute(
            path: '/details',
            builder: (context, state) => ProductDetailsScreen(product: sareeProduct),
          ),
          GoRoute(
            path: AppRoutes.customerPayment,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CustomerPaymentScreen(
                subtotal: (extra?['subtotal'] as num?)?.toDouble(),
                total: (extra?['total'] as num?)?.toDouble(),
                items: extra?['items'] as List<dynamic>?,
                cartItems: extra?['cartItems'] as List<dynamic>?,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Increase quantity to 2
      final addIconFinder = find.byIcon(Icons.add);
      expect(addIconFinder, findsOneWidget);
      await tester.tap(addIconFinder);
      await tester.pumpAndSettle();

      // Verify quantity is now 2
      expect(find.text('2'), findsOneWidget);

      // Tap Buy Now
      final buyNowFinder = find.widgetWithText(ElevatedButton, 'Buy Now');
      expect(buyNowFinder, findsOneWidget);
      await tester.tap(buyNowFinder);
      await tester.pumpAndSettle();

      // Verify navigation to Payment Screen occurred
      expect(find.byType(CustomerPaymentScreen), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);

      // Verify Itemized craft piece is displayed
      expect(find.text('SELECTED CRAFT PIECES'), findsOneWidget);
      expect(find.text('Handspun Kanchipuram Pure Silk Saree'), findsOneWidget);
      expect(find.textContaining('Lakshmi Devi • Qty: 2'), findsOneWidget);

      // Verify unit price (₹14,500) and calculated total (14,500 * 2 = 29,000)
      expect(find.textContaining('29,000'), findsWidgets);
      expect(find.textContaining('14,500 ea'), findsOneWidget);
    });
  });

  group('4. Payment Screen Itemization & Back Navigation Tests', () {
    testWidgets('Payment screen itemizes selected craft correctly', (tester) async {
      final bowlProduct = MockBuyerData.products.firstWhere((p) => p.id == 'KRY-PRD-02');

      await tester.pumpWidget(
        buildTestableApp(
          child: CustomerPaymentScreen(
            subtotal: 1850.0,
            total: 1850.0,
            items: [
              {
                'product': bowlProduct,
                'quantity': 1,
              }
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Order Summary header
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('SELECTED CRAFT PIECES'), findsOneWidget);

      // Check itemization
      expect(find.text('Terracotta Acoustic Sound Bowl & Planter'), findsOneWidget);
      expect(find.textContaining('Murugesan Perumal • Qty: 1'), findsOneWidget);
      expect(find.textContaining('1,850'), findsWidgets);

      // Check payment options
      expect(find.text('Choose Payment Method'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.textContaining('Google Pay, PhonePe'), findsOneWidget);
    });

    testWidgets('Back button in Payment screen pops cleanly', (tester) async {
      bool popped = false;

      final router = GoRouter(
        initialLocation: '/payment',
        routes: [
          GoRoute(
            path: '/payment',
            builder: (context, state) => CustomerPaymentScreen(
              subtotal: 1850.0,
              total: 1850.0,
              items: [
                {
                  'product': MockBuyerData.products.first,
                  'quantity': 1,
                }
              ],
            ),
          ),
          GoRoute(
            path: AppRoutes.customerExplore,
            builder: (context, state) {
              popped = true;
              return const Scaffold(body: Text('Explore Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Since there was no history stack, fallback safely navigated to Explore Screen
      expect(popped || find.text('Explore Screen').evaluate().isNotEmpty, true);
    });
  });
}
