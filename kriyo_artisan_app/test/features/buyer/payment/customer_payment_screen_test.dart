import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/l10n/app_localizations.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';
import 'package:kriyo_artisan_app/features/buyer/payment/customer_payment_screen.dart';

void main() {
  group('CustomerPaymentScreen Widget Tests', () {
    testWidgets('Renders empty cart prevention state when no items and total is zero',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: CustomerPaymentScreen(
              cartItems: [],
              total: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Explore Crafts'), findsOneWidget);
    });

    testWidgets('Renders Order Summary, 256-Bit SSL badge, and default UPI payment method',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testProduct = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: CustomerPaymentScreen(
              items: [testProduct],
              subtotal: 12500,
              discount: 500,
              deliveryFee: 0,
              total: 12000,
              couponCode: 'HERITAGE500',
              address: const {
                'name': 'Priya Sundaram',
                'address': 'Flat 402, Heritage Residency, Indiranagar',
                'city': 'Bengaluru, Karnataka - 560001',
                'phone': '+91 98765 43210',
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Trust Header
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('256-Bit SSL Encrypted'), findsOneWidget);

      // 2. Verify Order Summary Card
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('₹12,500'), findsOneWidget);
      expect(find.text('Coupon (HERITAGE500)'), findsOneWidget);
      expect(find.text('-₹500'), findsOneWidget);
      expect(find.text('Heritage Delivery'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Total Payable'), findsWidgets);
      expect(find.text('₹12,000'), findsWidgets);

      // 3. Verify Payment Methods Available
      expect(find.text('UPI'), findsOneWidget);
      expect(find.textContaining('Google Pay, PhonePe, Paytm'), findsOneWidget);
      expect(find.text('Debit Card'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('Net Banking'), findsOneWidget);
      expect(find.text('Cash on Delivery (COD)'), findsOneWidget);

      // 4. Default UPI CTA
      expect(find.text('Pay via UPI • ₹12,000'), findsOneWidget);
    });

    testWidgets('Switching to Cash on Delivery adds convenience fee and updates CTA to Place Order',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testProduct = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: CustomerPaymentScreen(
              items: [testProduct],
              subtotal: 5000,
              discount: 0,
              deliveryFee: 150,
              total: 5150,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Cash on Delivery tile
      final codFinder = find.text('Cash on Delivery (COD)');
      await tester.tap(codFinder);
      await tester.pumpAndSettle();

      // COD Convenience fee should now be visible (+₹50)
      expect(find.text('COD Convenience Fee'), findsOneWidget);
      expect(find.text('₹50'), findsOneWidget);

      // Total should be updated (5150 + 50 = 5200)
      expect(find.text('₹5,200'), findsWidgets);

      // CTA should dynamically update to Place Order
      expect(find.text('Place Order • ₹5,200'), findsOneWidget);
    });

    testWidgets('Switching to Card updates CTA to Pay Securely',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testProduct = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: CustomerPaymentScreen(
              items: [testProduct],
              subtotal: 8000,
              discount: 0,
              deliveryFee: 0,
              total: 8000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Debit Card tile
      final cardFinder = find.text('Debit Card');
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify card form fields are present
      expect(find.text('Card Number'), findsOneWidget);
      expect(find.text('Cardholder Name'), findsOneWidget);
      expect(find.text('Expiry (MM/YY)'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);

      // CTA should dynamically update to Pay Securely
      expect(find.text('Pay Securely • ₹8,000'), findsOneWidget);
    });

    testWidgets('Switching to Net Banking updates CTA to Continue to Bank',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testProduct = MockBuyerData.products.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: CustomerPaymentScreen(
              items: [testProduct],
              subtotal: 4500,
              discount: 0,
              deliveryFee: 0,
              total: 4500,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Net Banking tile
      final netBankingFinder = find.text('Net Banking');
      await tester.tap(netBankingFinder);
      await tester.pumpAndSettle();

      // Verify bank selector is present
      expect(find.text('Select Your Bank'), findsOneWidget);

      // CTA should dynamically update to Continue to Bank
      expect(find.text('Continue to Bank • ₹4,500'), findsOneWidget);
    });
  });
}
