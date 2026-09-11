import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/shared/inputs/kriyo_filter_chip.dart';

void main() {
  group('KriyoFilterChip Zero Layout Shift & Stability Tests', () {
    testWidgets('selected and unselected chips have 100% identical dimensions', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: KriyoFilterChip(
                    label: 'Newest First',
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => isSelected = val);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Measure unselected size
      final unselectedFinder = find.byType(KriyoFilterChip);
      expect(unselectedFinder, findsOneWidget);
      final unselectedSize = tester.getSize(unselectedFinder);

      // Tap chip to select
      await tester.tap(unselectedFinder);
      await tester.pump();

      // Measure selected size
      final selectedFinder = find.byType(KriyoFilterChip);
      final selectedSize = tester.getSize(selectedFinder);

      // Verify exact dimension matching (0.0px difference)
      expect(selectedSize.width, equals(unselectedSize.width));
      expect(selectedSize.height, equals(unselectedSize.height));
      expect(selectedSize.height, equals(36.0));
    });

    testWidgets('neighboring chips in Wrap do not move when another chip is selected', (tester) async {
      String selectedOption = 'Newest First';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    KriyoFilterChip(
                      label: 'Newest First',
                      selected: selectedOption == 'Newest First',
                      onSelected: (_) => setState(() => selectedOption = 'Newest First'),
                    ),
                    KriyoFilterChip(
                      label: 'Oldest First',
                      selected: selectedOption == 'Oldest First',
                      onSelected: (_) => setState(() => selectedOption = 'Oldest First'),
                    ),
                    KriyoFilterChip(
                      label: 'Highest Value',
                      selected: selectedOption == 'Highest Value',
                      onSelected: (_) => setState(() => selectedOption = 'Highest Value'),
                    ),
                    KriyoFilterChip(
                      label: 'Priority Attention',
                      selected: selectedOption == 'Priority Attention',
                      onSelected: (_) => setState(() => selectedOption = 'Priority Attention'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final chip1 = find.widgetWithText(KriyoFilterChip, 'Newest First');
      final chip2 = find.widgetWithText(KriyoFilterChip, 'Oldest First');
      final chip3 = find.widgetWithText(KriyoFilterChip, 'Highest Value');
      final chip4 = find.widgetWithText(KriyoFilterChip, 'Priority Attention');

      // Record baseline positions
      final chip1PosBefore = tester.getTopLeft(chip1);
      final chip2PosBefore = tester.getTopLeft(chip2);
      final chip3PosBefore = tester.getTopLeft(chip3);
      final chip4PosBefore = tester.getTopLeft(chip4);

      // Tap "Oldest First"
      await tester.tap(chip2);
      await tester.pump();

      // Positions of ALL chips must remain completely stable!
      expect(tester.getTopLeft(chip1), equals(chip1PosBefore));
      expect(tester.getTopLeft(chip2), equals(chip2PosBefore));
      expect(tester.getTopLeft(chip3), equals(chip3PosBefore));
      expect(tester.getTopLeft(chip4), equals(chip4PosBefore));

      // Tap "Priority Attention"
      await tester.tap(chip4);
      await tester.pump();

      expect(tester.getTopLeft(chip1), equals(chip1PosBefore));
      expect(tester.getTopLeft(chip2), equals(chip2PosBefore));
      expect(tester.getTopLeft(chip3), equals(chip3PosBefore));
      expect(tester.getTopLeft(chip4), equals(chip4PosBefore));
    });

    testWidgets('rapid filter toggling produces immediate state updates without error', (tester) async {
      String current = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  children: ['All', 'Paid', 'Pending'].map((opt) {
                    return KriyoFilterChip(
                      label: opt,
                      selected: current == opt,
                      onSelected: (_) => setState(() => current = opt),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );

      final paidFinder = find.widgetWithText(KriyoFilterChip, 'Paid');
      final pendingFinder = find.widgetWithText(KriyoFilterChip, 'Pending');
      final allFinder = find.widgetWithText(KriyoFilterChip, 'All');

      // Rapidly tap All -> Paid -> Pending -> All
      await tester.tap(paidFinder);
      await tester.pump();
      expect(current, equals('Paid'));

      await tester.tap(pendingFinder);
      await tester.pump();
      expect(current, equals('Pending'));

      await tester.tap(allFinder);
      await tester.pump();
      expect(current, equals('All'));
    });

    testWidgets('multilingual filter labels in Tamil and Hindi render stably with 36dp height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: const [
                KriyoFilterChip(label: 'புதியவை முதலில்', selected: true),
                KriyoFilterChip(label: 'பழையவை முதலில்', selected: false),
                KriyoFilterChip(label: 'नवीनतम पहले', selected: true),
                KriyoFilterChip(label: 'पुरातन पहले', selected: false),
              ],
            ),
          ),
        ),
      );

      final tamilSelected = find.widgetWithText(KriyoFilterChip, 'புதியவை முதலில்');
      final tamilUnselected = find.widgetWithText(KriyoFilterChip, 'பழையவை முதலில்');
      final hindiSelected = find.widgetWithText(KriyoFilterChip, 'नवीनतम पहले');
      final hindiUnselected = find.widgetWithText(KriyoFilterChip, 'पुरातन पहले');

      expect(tester.getSize(tamilSelected).height, equals(36.0));
      expect(tester.getSize(tamilUnselected).height, equals(36.0));
      expect(tester.getSize(hindiSelected).height, equals(36.0));
      expect(tester.getSize(hindiUnselected).height, equals(36.0));
    });
  });
}
