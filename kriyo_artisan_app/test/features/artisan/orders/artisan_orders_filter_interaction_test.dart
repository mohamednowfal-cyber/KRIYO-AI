import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_orders_provider.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_orders_screen.dart';
import 'package:kriyo_artisan_app/shared/inputs/kriyo_filter_chip.dart';

void main() {
  testWidgets('Artisan Orders Filter & Sort bottom sheet opens, selects filters without shake, and applies cleanly', (tester) async {
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

    // 1. Verify Orders screen initial state
    expect(find.text('Orders'), findsOneWidget);

    // 2. Tap Filter action in AppBar
    final filterButton = find.byTooltip('Filter Orders');
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // 3. Verify Filter & Sort sheet appears
    expect(find.text('Filter & Sort Orders'), findsOneWidget);
    expect(find.text('Sort By'), findsOneWidget);
    expect(find.text('Date Received'), findsOneWidget);
    expect(find.text('Payment Status'), findsOneWidget);
    expect(find.text('Production Attention'), findsOneWidget);

    // 4. Test Sort By selection: tap "Oldest First"
    final oldestFirstChip = find.widgetWithText(KriyoFilterChip, 'Oldest First');
    expect(oldestFirstChip, findsOneWidget);
    await tester.tap(oldestFirstChip);
    await tester.pump(); // Immediate update, no long animation delay

    // Verify "Oldest First" is selected
    KriyoFilterChip oldestWidget = tester.widget(oldestFirstChip);
    expect(oldestWidget.selected, isTrue);

    // Tap "Highest Value"
    final highestValueChip = find.widgetWithText(KriyoFilterChip, 'Highest Value');
    await tester.tap(highestValueChip);
    await tester.pump();
    KriyoFilterChip highestWidget = tester.widget(highestValueChip);
    expect(highestWidget.selected, isTrue);

    // 5. Test Date Received: tap "This Week"
    final thisWeekChip = find.widgetWithText(KriyoFilterChip, 'This Week');
    await tester.tap(thisWeekChip);
    await tester.pump();
    KriyoFilterChip thisWeekWidget = tester.widget(thisWeekChip);
    expect(thisWeekWidget.selected, isTrue);

    // 6. Test Payment Status: tap "Paid"
    final paidChip = find.widgetWithText(KriyoFilterChip, 'Paid');
    await tester.tap(paidChip);
    await tester.pump();
    KriyoFilterChip paidWidget = tester.widget(paidChip);
    expect(paidWidget.selected, isTrue);

    // 7. Test Production Attention: tap "Attention Required"
    final attentionChip = find.widgetWithText(KriyoFilterChip, 'Attention Required');
    await tester.tap(attentionChip);
    await tester.pump();
    KriyoFilterChip attentionWidget = tester.widget(attentionChip);
    expect(attentionWidget.selected, isTrue);

    // 8. Test Clear All button
    final clearAllButton = find.text('Clear All');
    expect(clearAllButton, findsOneWidget);
    await tester.tap(clearAllButton);
    await tester.pump();

    // After Clear All, Newest First should be default selected
    final newestFirstChip = find.widgetWithText(KriyoFilterChip, 'Newest First');
    KriyoFilterChip newestWidget = tester.widget(newestFirstChip);
    expect(newestWidget.selected, isTrue);

    // Select "Paid" again
    await tester.tap(paidChip);
    await tester.pump();
    paidWidget = tester.widget(paidChip);
    expect(paidWidget.selected, isTrue);

    // 9. Tap Apply Filters
    final applyButton = find.text('Apply Filters');
    expect(applyButton, findsOneWidget);
    await tester.ensureVisible(applyButton);
    await tester.pumpAndSettle();
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // 10. Verify sheet is dismissed cleanly and back on Orders screen
    expect(find.text('Filter & Sort Orders'), findsNothing);
    expect(find.text('Orders'), findsOneWidget);
  });
}
