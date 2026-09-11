import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/l10n/app_localizations.dart';
import 'package:kriyo_artisan_app/features/buyer/checkout/checkout_screen.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';

void main() {
  testWidgets('CheckoutScreen renders address, price details, and payment methods',
      (WidgetTester tester) async {
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
          home: CheckoutScreen(
            items: [testProduct],
            total: 16350,
            subtotal: 16850,
            discount: 500,
            deliveryFee: 0,
            couponCode: 'KRIYOHERITAGE',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Delivery Address header
    expect(find.text('Deliver to'), findsOneWidget);

    // Verify Price Details breakdown
    expect(find.text('Price Details'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('₹16850'), findsOneWidget);
    expect(find.text('Coupon Discount'), findsOneWidget);
    expect(find.text('-₹500'), findsOneWidget);
    expect(find.text('KRIYOHERITAGE'), findsOneWidget);
    expect(find.text('Total Payable'), findsWidgets);

    // Verify Payment Methods
    expect(find.textContaining('Payment Method'), findsWidgets);
    expect(find.textContaining('Card'), findsWidgets);
    expect(find.textContaining('Net Banking'), findsWidgets);
    expect(find.textContaining('Cash on Delivery'), findsWidgets);

    // Verify CTA button to continue to payment
    expect(find.byType(ElevatedButton), findsWidgets);
    expect(find.textContaining('Continue to Payment'), findsOneWidget);
  });
}
