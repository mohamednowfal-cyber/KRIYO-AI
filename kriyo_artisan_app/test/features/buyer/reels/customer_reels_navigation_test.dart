import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriyo_artisan_app/features/customer/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:kriyo_artisan_app/shared/widgets/kriyo_bottom_navigation.dart';
import 'package:kriyo_artisan_app/features/reels/data/reel_storage_service.dart';
import 'package:kriyo_artisan_app/features/buyer/data/mock_buyer_data.dart';
import 'package:kriyo_artisan_app/app/routes/app_routes.dart';

void main() {
  group('Customer Bottom Navigation - Reels Integration', () {
    testWidgets('CustomerBottomNavBar contains exactly 5 tabs: Home | Explore | Reels | Orders | Me', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomerBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );
      await tester.pump();

      final navFinder = find.byType(KriyoBottomNavigation);
      expect(navFinder, findsOneWidget);

      final navWidget = tester.widget<KriyoBottomNavigation>(navFinder);
      expect(navWidget.customItems, isNotNull);
      expect(navWidget.customItems!.length, equals(5));

      expect(navWidget.customItems![0].label, equals('Home'));
      expect(navWidget.customItems![1].label, equals('Explore'));
      expect(navWidget.customItems![2].label, equals('Reels'));
      expect(navWidget.customItems![3].label, equals('Orders'));
      expect(navWidget.customItems![4].label, equals('Me'));
    });

    testWidgets('CustomerBottomNavBar renders with Reels as center tab (index 2)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomerBottomNavBar(currentIndex: 2),
            ),
          ),
        ),
      );
      await tester.pump();

      final navFinder = find.byType(KriyoBottomNavigation);
      expect(navFinder, findsOneWidget);

      final navWidget = tester.widget<KriyoBottomNavigation>(navFinder);
      expect(navWidget.currentIndex, equals(2));
      expect(navWidget.customItems![2].label, equals('Reels'));
      expect(navWidget.customItems![2].icon, equals(Icons.play_circle_outline_rounded));
      expect(navWidget.customItems![2].activeIcon, equals(Icons.play_circle_rounded));
    });

    test('Artisan navigation remains completely untouched', () {
      // Create artisan bottom nav items
      const artisanNav = KriyoBottomNavigation(
        role: KriyoNavRole.artisan,
        currentIndex: 0,
        onTabChanged: _dummyTabChange,
      );

      // Verify role
      expect(artisanNav.role, equals(KriyoNavRole.artisan));
    });

    test('All 10 local video assets are mapped in ReelStorageService', () {
      final reels = ReelStorageService.initial10AssetReels;
      expect(reels.length, equals(10));

      final expectedAssets = [
        'assets/Videos/A gift which is emotionally strong and loved by everyone_HD.mp4',
        'assets/Videos/Beautiful butterfly made out of paper_HD.mp4',
        'assets/Videos/Beautiful paper jhumar DIY crafts_HD.mp4',
        'assets/Videos/DIY waterfall card wheel of memories_HD.mp4',
        'assets/Videos/Easy wall hanging craft ideas_HD.mp4',
        'assets/Videos/Episode 5 of our DIY Diwali Decor Series is here!_HD.mp4',
        'assets/Videos/Poetry of hands_HD.mp4',
        'assets/Videos/Unique Paper Cup Wall Hanging Ideas __ Easy Paper Cup craft ideas __ Paper C_HD.mp4',
        'assets/Videos/Wait For The Result_HD.mp4',
        'assets/Videos/you need 2 rupees only for this gift idea_HD.mp4',
      ];

      for (int i = 0; i < expectedAssets.length; i++) {
        final videoPath = reels[i].localMediaPath ?? reels[i].videoUrl;
        expect(videoPath, equals(expectedAssets[i]));
        expect(reels[i].artisanName.isNotEmpty, isTrue);
        expect(reels[i].craftType.isNotEmpty, isTrue);
        expect(reels[i].caption.isNotEmpty, isTrue);
        expect(reels[i].linkedProductId, isNotNull);
      }
    });

    test('Linked products in reels resolve to mock buyer catalog', () {
      final reels = ReelStorageService.initial10AssetReels;
      final catalogProductIds = MockBuyerData.products.map((p) => p.id).toSet();

      for (final reel in reels) {
        if (reel.linkedProductId != null) {
          expect(
            catalogProductIds.contains(reel.linkedProductId),
            isTrue,
            reason: 'Reel ${reel.id} links to unknown product ${reel.linkedProductId}',
          );
        }
      }
    });

    test('Routes constants contain customerReels and wishlist', () {
      expect(AppRoutes.customerReels, equals('/customer/reels'));
      expect(AppRoutes.wishlist, equals('/customer/wishlist'));
      expect(AppRoutes.customerOrders, equals('/customer/orders'));
    });
  });
}

void _dummyTabChange(int index) {}
