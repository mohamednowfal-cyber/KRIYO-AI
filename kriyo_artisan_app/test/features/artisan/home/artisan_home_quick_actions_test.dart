import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/features/artisan/home/artisan_home_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/inventory/providers/artisan_inventory_provider.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({GoRouter? router, ProviderContainer? container}) {
    final testRouter = router ??
        GoRouter(
          initialLocation: AppRoutes.home,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const ArtisanHomeScreen(),
            ),
            GoRoute(
              path: AppRoutes.addProduct,
              builder: (context, state) => const Scaffold(body: Text('Add Product Screen')),
            ),
            GoRoute(
              path: AppRoutes.addHeritage,
              builder: (context, state) => const Scaffold(body: Text('Add Heritage Screen')),
            ),
            GoRoute(
              path: AppRoutes.opportunities,
              builder: (context, state) => const Scaffold(body: Text('Bulk Opportunities Screen')),
            ),
            GoRoute(
              path: AppRoutes.inventory,
              builder: (context, state) => const Scaffold(body: Text('Inventory Screen')),
            ),
            GoRoute(
              path: AppRoutes.updateStock,
              builder: (context, state) => const Scaffold(body: Text('Update Stock Screen')),
            ),
            GoRoute(
              path: AppRoutes.productionCapacity,
              builder: (context, state) => const Scaffold(body: Text('Production Capacity Screen')),
            ),
            GoRoute(
              path: AppRoutes.orders,
              builder: (context, state) => const Scaffold(body: Text('Orders Screen')),
            ),
          ],
        );

    final app = MaterialApp.router(
      routerConfig: testRouter,
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: app,
      );
    }

    return ProviderScope(child: app);
  }

  void setupScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Artisan Home Screen - Quick Actions & Inventory Refactoring', () {
    testWidgets('1. Quick Actions: Add Heritage & Add Product exist, Add Memory removed, Bulk Orders added', (tester) async {
      setupScreen(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Quick Actions Header
      expect(find.text('Quick Actions'), findsOneWidget);

      // Add Product & Add Heritage exist
      expect(find.text('Add Product'), findsOneWidget);
      expect(find.text('Add Heritage'), findsOneWidget);

      // Add Memory must NOT exist
      expect(find.text('Add Memory'), findsNothing);

      // Bulk Orders must exist
      expect(find.text('Bulk Orders'), findsOneWidget);

      // Orders quick action exists
      expect(find.text('Orders'), findsWidgets);
    });

    testWidgets('2. Tapping Bulk Orders navigates to Bulk Opportunities', (tester) async {
      setupScreen(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final bulkOrdersBtn = find.text('Bulk Orders');
      expect(bulkOrdersBtn, findsOneWidget);

      await tester.tap(bulkOrdersBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bulk Opportunities Screen'), findsOneWidget);
    });

    testWidgets('3. AI Suggestions section is completely removed from Artisan Home', (tester) async {
      setupScreen(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // AI Suggestions card title must NOT exist
      expect(find.text('AI Suggestions'), findsNothing);
      expect(find.textContaining('wedding season demand'), findsNothing);
    });

    testWidgets('4. Inventory Card displays 12 products, 48 in stock, 3 low stock, 2 in production, and capacity distinction', (tester) async {
      setupScreen(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Inventory Card Header
      expect(find.text('Inventory'), findsWidgets);
      expect(find.text('Manage Inventory'), findsOneWidget);

      // Metric labels
      expect(find.text('Products'), findsWidgets);
      expect(find.text('In Stock'), findsOneWidget);
      expect(find.text('Low Stock'), findsWidgets);
      expect(find.text('Production'), findsOneWidget);

      // Seeded default metric values
      expect(find.text('12'), findsOneWidget); // 12 Products
      expect(find.text('48'), findsWidgets);  // 48 in stock
      expect(find.text('3'), findsWidgets);   // 3 Low Stock
      expect(find.text('2'), findsWidgets);   // 2 in production

      // Distinction banner: Current Stock ≠ Weekly Capacity
      expect(find.textContaining('Current Stock (48) ≠ Weekly Capacity (10/wk)'), findsOneWidget);

      // Action buttons
      expect(find.text('Update Stock'), findsOneWidget);
      expect(find.text('Production Capacity'), findsOneWidget);
      expect(find.text('View Inventory'), findsOneWidget);
    });

    testWidgets('5. Inventory Action Buttons Navigate Correctly', (tester) async {
      setupScreen(tester);

      // Test Update Stock navigation
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Stock'));
      await tester.pumpAndSettle();
      expect(find.text('Update Stock Screen'), findsOneWidget);

      // Rebuild and test Production Capacity navigation
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Production Capacity'));
      await tester.pumpAndSettle();
      expect(find.text('Production Capacity Screen'), findsOneWidget);

      // Rebuild and test View Inventory navigation
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Inventory'));
      await tester.pumpAndSettle();
      expect(find.text('Inventory Screen'), findsOneWidget);
    });

    testWidgets('6. Inventory Card dynamically reflects stock changes from artisanInventoryProvider', (tester) async {
      setupScreen(tester);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Initial stock: 48
      expect(container.read(artisanInventoryProvider).totalStock, 48);

      // Update stock of first item by +5
      final firstItem = container.read(artisanInventoryProvider).items.first;
      await container.read(artisanInventoryProvider.notifier).updateStock(firstItem.id, firstItem.stock + 5);

      await tester.pumpAndSettle();

      // New total stock should be 53
      expect(container.read(artisanInventoryProvider).totalStock, 53);
      expect(find.text('53'), findsWidgets);
      expect(find.textContaining('Current Stock (53) ≠ Weekly Capacity (10/wk)'), findsOneWidget);
    });
  });
}
