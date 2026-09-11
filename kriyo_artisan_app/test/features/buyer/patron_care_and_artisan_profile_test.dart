import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/features/buyer/settings/customer_support_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/order_delivery_support_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/order_support_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/heritage_authenticity_support_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/payments_refunds_support_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/custom_commission_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/patron_care/screens/support_requests_list_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/artisans/saved_artisans_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/artisans/artisan_details_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';

import 'package:flutter/services.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
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

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async => true,
    );
  });

  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    HttpOverrides.global = null;
  });
  testWidgets('CustomerSupportScreen renders all options and contacts', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CustomerSupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patron Care & Guild Support'), findsOneWidget);
    expect(find.text('Order Tracking & Delivery Inquiries'), findsOneWidget);
    expect(find.text('Heritage Authenticity & GI Tag Seal'), findsOneWidget);
    expect(find.text('Payments, Refunds & Invoices'), findsOneWidget);
    expect(find.text('Custom Artisan Commission Inquiries'), findsOneWidget);
    expect(find.text('Artisan Guild Helpline'), findsOneWidget);
    expect(find.text('Email Patron Support'), findsOneWidget);
  });

  testWidgets('OrderDeliverySupportScreen renders orders and buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OrderDeliverySupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order & Delivery Support'), findsOneWidget);
    expect(find.text('Get Help'), findsWidgets);
    expect(find.text('Track Order'), findsWidgets);
  });

  testWidgets('OrderSupportScreen validates input and generates ticket', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OrderSupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order Support'), findsOneWidget);
    expect(find.text('Submit Support Request'), findsOneWidget);

    // Enter description
    await tester.enterText(find.byType(TextField), 'Delivery is delayed by 2 days, please update.');
    final submitBtn = find.text('Submit Support Request');
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Support Request Submitted'), findsOneWidget);
    expect(find.textContaining('Ticket #SUP-'), findsOneWidget);
  });

  testWidgets('HeritageAuthenticitySupportScreen shows provenance information', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HeritageAuthenticitySupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heritage Authenticity Support'), findsOneWidget);
    expect(find.text('GI Tag Verification'), findsOneWidget);
    expect(find.text('Artisan Verification'), findsOneWidget);
    expect(find.text('Check Authenticity'), findsOneWidget);
    expect(find.text('Report Authenticity Concern'), findsOneWidget);
  });

  testWidgets('PaymentsRefundsSupportScreen displays actions and transactions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PaymentsRefundsSupportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payments & Refunds Support'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Refunds'), findsOneWidget);
    expect(find.text('Payment Help'), findsWidgets);
    expect(find.text('View Invoice'), findsWidgets);
  });

  testWidgets('CustomCommissionScreen submits inquiry', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CustomCommissionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Custom Commission'), findsOneWidget);
    expect(find.text('Send Commission Inquiry'), findsOneWidget);

    // Fill form
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '9-yard Kanchipuram Silk Drape');
    await tester.enterText(textFields.at(4), 'Gold zari peacock border with pure silk');

    final sendBtn = find.text('Send Commission Inquiry');
    await tester.ensureVisible(sendBtn);
    await tester.pumpAndSettle();
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    expect(find.text('Commission Inquiry Sent'), findsOneWidget);
    expect(find.textContaining('Inquiry ID: #CMS-'), findsOneWidget);
  });

  testWidgets('SupportRequestsListScreen displays tabs and ticket list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SupportRequestsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Requests'), findsOneWidget);
    expect(find.textContaining('In Review'), findsWidgets);
    expect(find.textContaining('Open'), findsWidgets);
    expect(find.textContaining('Resolved'), findsWidgets);
  });

  testWidgets('SavedArtisansScreen and ArtisanDetailsScreen functionality', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SavedArtisansScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patronized Artisans'), findsOneWidget);
    expect(find.text('View Profile & Works'), findsWidgets);
  });

  testWidgets('ArtisanDetailsScreen shows header, about, story, and works tabs', (tester) async {
    final artisan = MockBuyerData.artisans.first;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ArtisanDetailsScreen(artisan: artisan),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(artisan.name), findsOneWidget);
    expect(find.text('✓ KRIYO Verified Artisan'), findsOneWidget);
    expect(find.text('About the Artisan'), findsOneWidget);
    expect(find.text('Heritage Story'), findsOneWidget);
    expect(find.textContaining('Completed Works'), findsOneWidget);
    expect(find.textContaining('Current / Ongoing Works'), findsOneWidget);
  });
}
