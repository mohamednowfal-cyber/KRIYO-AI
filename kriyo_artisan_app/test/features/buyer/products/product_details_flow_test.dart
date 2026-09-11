import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';
import 'package:kriyo_artisan_app/features/buyer/products/product_details_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/products/screens/product_craft_journey_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/products/services/craft_journey_service.dart';
import 'package:kriyo_artisan_app/features/buyer/products/services/product_gurukul_mapping_service.dart';

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

  group('Product Gurukul Mapping Service Tests', () {
    test('Maps handloom/saree products to GRK-CRS-01', () {
      final product = MockBuyerData.products.firstWhere((p) => p.craftType.contains('Weaving') || p.title.contains('Saree'));
      final courseId = ProductGurukulMappingService.getCourseIdForProduct(product);
      expect(courseId, equals('GRK-CRS-01'));
      final title = ProductGurukulMappingService.getCourseTitleForProduct(product);
      expect(title, contains('Silk'));
    });

    test('Maps terracotta products to GRK-CRS-02', () {
      final product = MockBuyerData.products.firstWhere((p) => p.title.toLowerCase().contains('terracotta') || p.craftType.toLowerCase().contains('terracotta'));
      final courseId = ProductGurukulMappingService.getCourseIdForProduct(product);
      expect(courseId, equals('GRK-CRS-02'));
      final title = ProductGurukulMappingService.getCourseTitleForProduct(product);
      expect(title, contains('Terracotta'));
    });

    test('Maps painting products to GRK-CRS-03', () {
      const paintingProduct = CraftProductItem(
        id: 'KRY-TEST-PAINT',
        title: 'Tanjore 24K Gold Foil Painting',
        craftType: 'Tanjore Painting',
        region: 'Thanjavur, Tamil Nadu',
        artisanName: 'Ramanathan Achari',
        artisanRole: 'Guild Master',
        artisanAvatar: '',
        price: 18000,
        originalPrice: 22000,
        rating: 4.9,
        reviewsCount: 12,
        imageUrl: '',
        galleryImages: [],
        description: 'Tanjore art',
        craftStory: 'Traditional lineage',
        audioDuration: '03:10',
        techniques: ['Gold Leaf'],
        materials: ['24K Gold Leaf'],
        clusterName: 'Thanjavur Art Guild',
        daysToCraft: 22,
      );
      final courseId = ProductGurukulMappingService.getCourseIdForProduct(paintingProduct);
      expect(courseId, equals('GRK-CRS-03'));
      final title = ProductGurukulMappingService.getCourseTitleForProduct(paintingProduct);
      expect(title, contains('Gold Foil'));
    });

    test('Maps wood carving products to GRK-CRS-04', () {
      final product = MockBuyerData.products.firstWhere((p) => p.title.toLowerCase().contains('wood') || p.craftType.toLowerCase().contains('wood'));
      final courseId = ProductGurukulMappingService.getCourseIdForProduct(product);
      expect(courseId, equals('GRK-CRS-04'));
      final title = ProductGurukulMappingService.getCourseTitleForProduct(product);
      expect(title, contains('Teakwood'));
    });
  });

  group('Craft Journey Service Tests', () {
    test('Generates 6-stage timeline for Handloom products', () {
      final product = MockBuyerData.products.first;
      final journey = CraftJourneyService.getJourneyForProduct(product);

      expect(journey.stages.length, greaterThanOrEqualTo(5));
      expect(journey.stages.first.title, contains('Silk'));
      expect(journey.stages.first.artisanSecretTip.isNotEmpty, isTrue);
      expect(journey.stages.first.toolsAndMaterials.isNotEmpty, isTrue);
      expect(journey.heritageFact.isNotEmpty, isTrue);
    });

    test('Generates authentic timeline for Terracotta products', () {
      final product = MockBuyerData.products.firstWhere((p) => p.title.toLowerCase().contains('terracotta'));
      final journey = CraftJourneyService.getJourneyForProduct(product);

      expect(journey.craftType, contains('Terracotta'));
      expect(journey.stages.length, greaterThanOrEqualTo(5));
      expect(journey.stages.any((s) => s.title.toLowerCase().contains('clay') || s.title.toLowerCase().contains('kiln')), isTrue);
    });

    test('Generates authentic timeline for Painting products', () {
      const paintingProduct = CraftProductItem(
        id: 'KRY-TEST-PAINT',
        title: 'Tanjore 24K Gold Foil Painting',
        craftType: 'Tanjore Painting',
        region: 'Thanjavur, Tamil Nadu',
        artisanName: 'Ramanathan Achari',
        artisanRole: 'Guild Master',
        artisanAvatar: '',
        price: 18000,
        originalPrice: 22000,
        rating: 4.9,
        reviewsCount: 12,
        imageUrl: '',
        galleryImages: [],
        description: 'Tanjore art',
        craftStory: 'Traditional lineage',
        audioDuration: '03:10',
        techniques: ['Gold Leaf'],
        materials: ['24K Gold Leaf'],
        clusterName: 'Thanjavur Art Guild',
        daysToCraft: 22,
      );
      final journey = CraftJourneyService.getJourneyForProduct(paintingProduct);

      expect(journey.craftType, contains('Painting'));
      expect(journey.stages.any((s) => s.title.toLowerCase().contains('gold') || s.title.toLowerCase().contains('gesso')), isTrue);
    });

    test('Generates authentic timeline for Wood carving products', () {
      final product = MockBuyerData.products.firstWhere((p) => p.title.toLowerCase().contains('wood'));
      final journey = CraftJourneyService.getJourneyForProduct(product);

      expect(journey.craftType, contains('Wood'));
      expect(journey.stages.any((s) => s.title.toLowerCase().contains('timber') || s.title.toLowerCase().contains('chisel')), isTrue);
    });
  });

  group('Product Craft Journey Screen Widget Tests', () {
    testWidgets('Renders all creation phases, heritage trivia, and back button', (tester) async {
      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ProductCraftJourneyScreen(product: product),
        ),
      );

      expect(find.text('Craft Journey & Lineage'), findsOneWidget);
      expect(find.text('The Living Loom Chronicle'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Creation Phases'), findsOneWidget);
      expect(find.textContaining('Back to'), findsOneWidget);
    });
  });

  group('Product Details Screen Tests', () {
    testWidgets('Renders product info, quantity counter, and Add to Cart / Buy Now buttons', (tester) async {
      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProductDetailsScreen(product: product),
          ),
        ),
      );

      // Verify Product title and price
      expect(find.text(product.title), findsOneWidget);
      expect(find.text('₹${product.price.toInt()}'), findsWidgets);

      // Verify buttons
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);

      // Verify initial quantity is 1
      expect(find.text('1'), findsWidgets);

      // Verify craft story section
      expect(find.text('The Story Behind This Craft'), findsOneWidget);
      expect(find.text('ORAL HERITAGE'), findsOneWidget);

      // Verify Gurukul and Behind-the-scenes journey links
      expect(find.text('Learn Craft'), findsOneWidget);
      expect(find.text('View Behind-the-Scenes Craft Journey'), findsOneWidget);
    });

    testWidgets('Quantity counter increments and decrements correctly', (tester) async {
      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProductDetailsScreen(product: product),
          ),
        ),
      );

      final plusBtn = find.byIcon(Icons.add);
      final minusBtn = find.byIcon(Icons.remove);

      // Tap '+'
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      // Quantity should now be 2
      expect(find.text('2'), findsWidgets);
      final subtotal2 = (product.price * 2).toInt();
      expect(find.text('₹$subtotal2'), findsOneWidget);

      // Tap '-'
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();

      // Quantity returns to 1
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('Add to Cart triggers single-shot success banner with VIEW CART button', (tester) async {
      final product = MockBuyerData.products.first;
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ProductDetailsScreen(product: product),
          ),
        ),
      );

      // Initially banner should NOT be visible
      expect(find.text('VIEW CART'), findsNothing);

      // Tap Add to Cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // animation

      // Banner should now be visible with product title and VIEW CART button
      expect(find.text('VIEW CART'), findsOneWidget);
      expect(find.text('Added ${product.title} to Cart!'), findsOneWidget);

      // Verify item was added to UserSession cart
      final cart = container.read(sessionProvider).customerCart;
      expect(cart.any((item) => item.id == product.id), isTrue);

      // Tap 'X' to manually dismiss
      final closeIcon = find.byIcon(Icons.close);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Banner is dismissed
      expect(find.text('VIEW CART'), findsNothing);
    });

    testWidgets('Banner auto-dismisses cleanly after 4.5 seconds', (tester) async {
      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProductDetailsScreen(product: product),
          ),
        ),
      );

      // Tap Add to Cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('VIEW CART'), findsOneWidget);

      // Advance time past 4.5 seconds
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pump(const Duration(milliseconds: 350));

      // Banner is auto-dismissed
      expect(find.text('VIEW CART'), findsNothing);
    });
  });
}
