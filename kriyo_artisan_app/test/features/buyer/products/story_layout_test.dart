import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';
import 'package:kriyo_artisan_app/features/buyer/products/product_details_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/products/widgets/product_story_section.dart';

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

  group('ProductStorySection & Story Behind The Craft Layout Tests', () {
    testWidgets('TEST 1 & 2: Short and Long English stories receive full card width (> 200px) and wrap naturally', (tester) async {
      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ProductStorySection(
                  product: product,
                  storyText: 'Every temple border motif is inspired by the ancient Brihadeeswara sculptures. My great-grandmother taught me how to count threads to maintain the symmetry.',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final audioTitleFinder = find.text('Artisan Oral Heritage Audio');
      expect(audioTitleFinder, findsOneWidget);

      final titleSize = tester.getSize(audioTitleFinder);
      // Verify width is substantial (over 200px), never squeezed into a 1-character column (< 30px)
      expect(titleSize.width, greaterThan(200.0));
      // Verify height is normal single/double line (< 40px), not 1100px vertical column
      expect(titleSize.height, lessThan(45.0));

      // Verify header title
      final headerFinder = find.text('The Story Behind This Craft');
      expect(headerFinder, findsOneWidget);
      final headerSize = tester.getSize(headerFinder);
      expect(headerSize.width, greaterThan(150.0));

      // Verify badge
      expect(find.text('ORAL HERITAGE'), findsOneWidget);
    });

    testWidgets('TEST 3: Tamil story text wraps naturally across full width without truncation', (tester) async {
      final product = MockBuyerData.products.first;
      const tamilStory = 'ஒவ்வொரு கோவில் எல்லை வடிவமும் பண்டைய பிரகதீஸ்வரர் சிற்பங்களால் ஈர்க்கப்பட்டுள்ளது. சமச்சீர்நிலையை பராமரிக்க நூல்களை எவ்வாறு எண்ணுவது என்பதை எனது கொள்ளுப் பாட்டி எனக்குக் கற்றுக் கொடுத்தார்.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ProductStorySection(
                  product: product,
                  storyText: tamilStory,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tamilFinder = find.text(tamilStory);
      expect(tamilFinder, findsOneWidget);
      final size = tester.getSize(tamilFinder);
      expect(size.width, greaterThan(250.0));
      expect(size.height, greaterThan(20.0));
    });

    testWidgets('TEST 4: Hindi story text wraps naturally across full width without truncation', (tester) async {
      final product = MockBuyerData.products.first;
      const hindiStory = 'हर मंदिर की सीमा की आकृति प्राचीन बृहदेश्वर मूर्तियों से प्रेरित है। मेरी परदादी ने मुझे समरूपता बनाए रखने के लिए धागे गिनना सिखाया था।';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ProductStorySection(
                  product: product,
                  storyText: hindiStory,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hindiFinder = find.text(hindiStory);
      expect(hindiFinder, findsOneWidget);
      final size = tester.getSize(hindiFinder);
      expect(size.width, greaterThan(250.0));
      expect(size.height, greaterThan(20.0));
    });

    testWidgets('TEST 6: Small Android screen (320x533) renders without RenderFlex overflow or single-letter column', (tester) async {
      tester.view.physicalSize = const Size(320, 533);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProductStorySection(product: product),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final audioTitleFinder = find.text('Artisan Oral Heritage Audio');
      expect(audioTitleFinder, findsOneWidget);

      final titleSize = tester.getSize(audioTitleFinder);
      // On 320px device, width should still be wide and comfortable (> 150px), not single-letter (< 30px)
      expect(titleSize.width, greaterThan(150.0));
      expect(titleSize.height, lessThan(80.0));

      // No RenderFlex overflow exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST 7: Large screen (412x915) uses available card width smoothly', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ProductStorySection(product: product),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final audioTitleFinder = find.text('Artisan Oral Heritage Audio');
      expect(audioTitleFinder, findsOneWidget);

      final titleSize = tester.getSize(audioTitleFinder);
      expect(titleSize.width, greaterThan(200.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST 8 & 9: Multiple distinct products render their respective stories and audio properly', (tester) async {
      for (final product in MockBuyerData.products.take(4)) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProductStorySection(product: product),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('The Story Behind This Craft'), findsOneWidget);
        expect(find.text(product.effectiveCraftStory), findsWidgets);
        expect(find.text('Artisan Oral Heritage Audio'), findsOneWidget);
        expect(find.textContaining(product.artisanName), findsWidgets);
      }
    });

    testWidgets('Full ProductDetailsScreen Integration: renders ProductStorySection without overflow', (tester) async {
      tester.view.physicalSize = const Size(392, 872);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final product = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProductDetailsScreen(product: product),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find story section
      expect(find.byType(ProductStorySection), findsOneWidget);
      expect(find.text('The Story Behind This Craft'), findsOneWidget);
      expect(find.text('ORAL HERITAGE'), findsOneWidget);

      // Verify bottom action bar is active
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
