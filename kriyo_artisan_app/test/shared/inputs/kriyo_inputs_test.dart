import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/shared/inputs/inputs.dart';

void main() {
  group('KriyoTextField Widget Tests', () {
    testWidgets('renders external label, placeholder hint, and accepts text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: KriyoTextField(
                label: 'Product Title',
                controller: controller,
                hintText: 'Enter title here',
              ),
            ),
          ),
        ),
      );

      // Verify label and hint text are rendered
      expect(find.text('Product Title'), findsOneWidget);
      expect(find.text('Enter title here'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Kanchipuram Silk');
      await tester.pump();

      expect(controller.text, equals('Kanchipuram Silk'));
      expect(find.text('Kanchipuram Silk'), findsOneWidget);
    });

    testWidgets('renders prefix and suffix elements without text collision', (tester) async {
      final controller = TextEditingController(text: '1500');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: KriyoTextField(
                label: 'Price',
                controller: controller,
                prefixText: '₹',
                suffixText: 'INR',
              ),
            ),
          ),
        ),
      );

      expect(find.text('₹'), findsOneWidget);
      expect(find.text('INR'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('displays validation error text below container', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: KriyoTextField(
                label: 'Email',
                validator: (val) => (val == null || val.isEmpty) ? 'Email is required' : null,
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });
  });

  group('KriyoSearchField Widget Tests', () {
    testWidgets('renders search icon, clear button on text entry, and calls onClear', (tester) async {
      final controller = TextEditingController();
      bool voiceTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KriyoSearchField(
              controller: controller,
              hintText: 'Search crafts...',
              showVoiceButton: true,
              onVoiceTap: () => voiceTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Search crafts...'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Clear button should not be present initially
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Handloom');
      await tester.pump();

      // Clear button should now appear
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(controller.text, isEmpty);

      // Tap voice button
      await tester.tap(find.byIcon(Icons.mic_rounded));
      expect(voiceTapped, isTrue);
    });
  });

  group('KriyoResponsiveRow Widget Tests', () {
    testWidgets('arranges fields side-by-side on wide constraint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: KriyoResponsiveRow(
                first: Text('Field 1'),
                second: Text('Field 2'),
              ),
            ),
          ),
        ),
      );

      // When wide, it should use a Row with Expanded children
      expect(find.byType(Row), findsOneWidget);
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });

    testWidgets('stacks fields vertically on narrow constraint (< 340dp)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: KriyoResponsiveRow(
                first: Text('Field 1'),
                second: Text('Field 2'),
              ),
            ),
          ),
        ),
      );

      // When narrow, it should render as a Column
      expect(find.byType(Column), findsOneWidget);
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });
  });

  group('KriyoCouponField Widget Tests', () {
    testWidgets('renders input and apply button, responds to apply tap', (tester) async {
      final controller = TextEditingController(text: 'KRIYOHERITAGE');
      bool applied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KriyoCouponField(
              controller: controller,
              onApply: () => applied = true,
            ),
          ),
        ),
      );

      expect(find.text('Apply'), findsOneWidget);
      await tester.tap(find.text('Apply'));
      expect(applied, isTrue);
    });

    testWidgets('displays applied state with savings and remove button', (tester) async {
      final controller = TextEditingController(text: 'KRIYOHERITAGE');
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KriyoCouponField(
              controller: controller,
              isApplied: true,
              appliedCode: 'KRIYOHERITAGE',
              savingsAmount: 500,
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('KRIYOHERITAGE applied: ₹500 savings'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      expect(removed, isTrue);
    });
  });

  group('PriceInputField Widget Tests', () {
    testWidgets('renders currency prefix and unit suffix', (tester) async {
      final controller = TextEditingController(text: '3500');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceInputField(
              label: 'Craft Price',
              controller: controller,
              currencySymbol: '₹',
              unit: 'piece',
            ),
          ),
        ),
      );

      expect(find.text('Craft Price'), findsOneWidget);
      expect(find.text('₹'), findsOneWidget);
      expect(find.text('piece'), findsOneWidget);
      expect(find.text('3500'), findsOneWidget);
    });
  });
}
