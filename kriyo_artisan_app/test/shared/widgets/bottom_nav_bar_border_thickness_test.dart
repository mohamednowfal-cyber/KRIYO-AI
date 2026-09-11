import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/shared/widgets/kriyo_bottom_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Navigation Bar Border Thickness Specifications (Both Roles)', () {
    test('KriyoNavigationTheme.artisan() has increased border thickness >= 2.0', () {
      final theme = KriyoNavigationTheme.artisan();
      expect(theme.borderWidth, greaterThanOrEqualTo(2.0));
      expect(theme.podBorderWidth, greaterThanOrEqualTo(2.5));
      expect(theme.borderWidth, equals(2.2));
      expect(theme.podBorderWidth, equals(2.8));
    });

    test('KriyoNavigationTheme.customer() has increased border thickness >= 2.0', () {
      final theme = KriyoNavigationTheme.customer();
      expect(theme.borderWidth, greaterThanOrEqualTo(2.0));
      expect(theme.podBorderWidth, greaterThanOrEqualTo(2.5));
      expect(theme.borderWidth, equals(2.2));
      expect(theme.podBorderWidth, equals(2.8));
    });

    testWidgets('Artisan bottom navigation bar renders with increased border thickness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: KriyoBottomNavigation(
              role: KriyoNavRole.artisan,
              currentIndex: 0,
              onTabChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      // Verify the pod container has the thicker border
      final podFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          if (dec.border is Border) {
            final border = dec.border as Border;
            return border.top.width >= 2.5;
          }
        }
        return false;
      });
      expect(podFinder, findsOneWidget);
    });

    testWidgets('Customer bottom navigation bar renders with increased border thickness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: KriyoBottomNavigation(
              role: KriyoNavRole.customer,
              currentIndex: 0,
              onTabChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      // Verify the pod container has the thicker border
      final podFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          if (dec.border is Border) {
            final border = dec.border as Border;
            return border.top.width >= 2.5;
          }
        }
        return false;
      });
      expect(podFinder, findsOneWidget);
    });
  });
}
