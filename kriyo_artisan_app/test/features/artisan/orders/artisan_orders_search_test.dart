import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_orders_screen.dart';

void main() {
  testWidgets('Artisan Orders Search Bar layout, typing, clear button, and empty state test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ArtisanOrdersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial screen title
    expect(find.text('Orders'), findsOneWidget);

    // Tap search action in AppBar
    final searchAction = find.byTooltip('Search Orders');
    expect(searchAction, findsOneWidget);
    await tester.tap(searchAction);
    await tester.pumpAndSettle();

    // Verify search TextField appears with proper hint
    final searchTextField = find.byType(TextField);
    expect(searchTextField, findsOneWidget);
    expect(find.text('Search orders, customers, products...'), findsOneWidget);

    // Clear button should not be present initially when empty
    expect(find.byTooltip('Clear search'), findsNothing);

    // Type query that matches an order: 'Anandhi'
    await tester.enterText(searchTextField, 'Anandhi');
    await tester.pumpAndSettle();

    // Clear button should now be visible and have at least 44x44 touch target
    final clearButton = find.byTooltip('Clear search');
    expect(clearButton, findsOneWidget);
    final clearButtonSize = tester.getSize(clearButton);
    expect(clearButtonSize.width, greaterThanOrEqualTo(44.0));
    expect(clearButtonSize.height, greaterThanOrEqualTo(44.0));

    // Type non-matching query to trigger empty state: 'huio9'
    await tester.enterText(searchTextField, 'huio9');
    await tester.pumpAndSettle();

    // Verify clean empty state appears
    expect(find.text('No Orders Found'), findsOneWidget);
    expect(find.text('Try a different order ID, customer name, or product.'), findsOneWidget);
    expect(find.text('Clear Search'), findsOneWidget);

    // Tap the clear button in search field
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // Query is cleared and empty state disappears
    expect(find.text('No Orders Found'), findsNothing);
    expect(find.byTooltip('Clear search'), findsNothing);
  });
}
