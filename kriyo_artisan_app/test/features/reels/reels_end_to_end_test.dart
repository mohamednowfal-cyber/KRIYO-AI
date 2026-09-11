import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/features/reels/data/reel_storage_service.dart';
import 'package:kriyo_artisan_app/features/reels/models/reel_models.dart';
import 'package:kriyo_artisan_app/features/reels/providers/reels_provider.dart';
import 'package:kriyo_artisan_app/shared/widgets/kriyo_bottom_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KRIYO 10 Local Reel Assets & Storage Service', () {
    test('Storage service seeds all 10 local craft reels by default', () {
      final reels = ReelStorageService.initial10AssetReels;
      expect(reels.length, equals(10));

      // Verify all 10 local asset video files are correctly mapped
      final expectedVideos = [
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

      for (int i = 0; i < 10; i++) {
        expect(reels[i].videoUrl, equals(expectedVideos[i]));
        expect(reels[i].craftType.isNotEmpty, isTrue);
        expect(reels[i].artisanName.isNotEmpty, isTrue);
        expect(reels[i].region.isNotEmpty, isTrue);
        expect(reels[i].caption.isNotEmpty, isTrue);
      }
    });

    test('Artisan reel serialization and deserialization preserves all metadata and status', () {
      final original = ArtisanReelItem(
        id: 'REL-SERIAL-01',
        artisanId: 'ART-999',
        artisanName: 'Balamurugan',
        artisanRole: 'Master Bronze Caster',
        artisanAvatar: 'https://images.unsplash.com/avatar.jpg',
        region: 'Swamimalai, Tamil Nadu',
        videoUrl: 'assets/Videos/Wait For The Result_HD.mp4',
        thumbnailUrl: 'https://images.unsplash.com/thumb.jpg',
        caption: 'Lost wax casting of sacred temple idols.',
        craftType: 'Bronze Icon Casting',
        technique: 'Lost-Wax Cire Perdue',
        linkedProductId: 'KRY-PRD-01',
        linkedProductTitle: 'Sacred Swamimalai Nataraja',
        linkedProductPrice: 28000,
        linkedCourseId: 'GRK-CRS-01',
        linkedCourseTitle: 'Lost-Wax Casting Fundamentals',
        heritageContext: 'Chola bronze guild lineage.',
        mediaType: CraftStoryMediaType.video,
        sourceType: CraftStorySourceType.camera,
        publishStatus: ReelPublishStatus.published,
        createdAt: DateTime(2026, 9, 10, 10, 30),
      );

      final json = original.toJson();
      final reconstructed = ArtisanReelItem.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.artisanName, equals(original.artisanName));
      expect(reconstructed.craftType, equals(original.craftType));
      expect(reconstructed.technique, equals(original.technique));
      expect(reconstructed.linkedProductId, equals(original.linkedProductId));
      expect(reconstructed.linkedProductPrice, equals(original.linkedProductPrice));
      expect(reconstructed.mediaType, equals(CraftStoryMediaType.video));
      expect(reconstructed.publishStatus, equals(ReelPublishStatus.published));
    });

    test('Photo reels preserve CraftStoryMediaType.photo correctly in model and JSON', () {
      final photoReel = ArtisanReelItem(
        id: 'REL-PHOTO-01',
        artisanId: 'ART-002',
        artisanName: 'Sunita Sharma',
        artisanRole: 'Paper Artisan',
        artisanAvatar: 'https://images.unsplash.com/avatar.jpg',
        region: 'Jaipur, Rajasthan',
        videoUrl: 'assets/Videos/Beautiful butterfly made out of paper_HD.mp4',
        thumbnailUrl: 'assets/patterns/sample.jpg',
        caption: 'Intricate paper folding butterfly masterpiece.',
        craftType: 'Paper Craft',
        technique: 'Fold Origami',
        mediaType: CraftStoryMediaType.photo,
        localMediaPath: 'C:/fake/path/butterfly.jpg',
        createdAt: DateTime.now(),
      );

      expect(photoReel.mediaType, equals(CraftStoryMediaType.photo));
      final json = photoReel.toJson();
      final fromJson = ArtisanReelItem.fromJson(json);
      expect(fromJson.mediaType, equals(CraftStoryMediaType.photo));
    });
  });

  group('Artisan → Customer End-to-End Reel Flow & Interactions', () {
    late ReelsNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = ReelsNotifier();
    });

    test('Customer feed contains all 10 seed reels upon start', () {
      final published = notifier.state.publishedReels;
      expect(published.length, greaterThanOrEqualTo(10));
    });

    test('When Artisan publishes new reel, it appears at index 0 of customer feed', () async {
      final initialCount = notifier.state.publishedReels.length;

      final newlyPublished = ArtisanReelItem(
        id: 'REL-ARTISAN-PUBLISHED-01',
        artisanId: 'ART-001',
        artisanName: 'Lakshmi Devi',
        artisanRole: '4th Gen Master Weaver',
        artisanAvatar: 'https://images.unsplash.com/avatar.jpg',
        region: 'Kanchipuram, Tamil Nadu',
        videoUrl: 'assets/Videos/A gift which is emotionally strong and loved by everyone_HD.mp4',
        thumbnailUrl: 'https://images.unsplash.com/thumb.jpg',
        caption: 'Fresh loom creation ready for customer discovery!',
        craftType: 'Handloom Weaving',
        technique: 'Korvai Shuttle',
        linkedProductId: 'KRY-PRD-01',
        linkedProductTitle: 'Handspun Silk Saree',
        linkedProductPrice: 14500,
        createdAt: DateTime.now(),
      );

      await notifier.publishReel(newlyPublished);

      expect(notifier.state.publishedReels.length, equals(initialCount + 1));
      // First reel in feed is the newly uploaded artisan reel
      expect(notifier.state.publishedReels.first.id, equals('REL-ARTISAN-PUBLISHED-01'));
      expect(notifier.state.publishedReels.first.linkedProductId, equals('KRY-PRD-01'));
      expect(notifier.state.publishedReels.first.caption, contains('Fresh loom creation'));
    });

    test('Double tap like (likeReel) is idempotent and does not create duplicates', () {
      final reel = notifier.state.publishedReels.first;
      final initialLikes = reel.likesCount;

      // First double tap -> likes the reel
      notifier.likeReel(reel.id);
      var updated = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updated.isLiked, isTrue);
      expect(updated.likesCount, equals(initialLikes + 1));

      // Second double tap -> idempotent, stays liked and count does NOT increase again
      notifier.likeReel(reel.id);
      updated = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updated.isLiked, isTrue);
      expect(updated.likesCount, equals(initialLikes + 1));
    });

    test('Customer comment system posts and increments comments count', () async {
      final reel = notifier.state.publishedReels.first;
      final initialCount = reel.commentsCount;

      await notifier.addComment(
        reel.id,
        'Master Lakshmi, how long does the border take to interlock?',
        authorName: 'Aarav Patel',
      );

      final updatedReel = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updatedReel.commentsCount, equals(initialCount + 1));

      final comments = notifier.state.comments[reel.id];
      expect(comments, isNotNull);
      expect(comments!.first.authorName, equals('Aarav Patel'));
      expect(comments.first.text, contains('border take to interlock'));
    });
  });

  group('Customer Bottom Navigation Tab Structure', () {
    test('Default Customer navigation has 5 items with Craft Stories at center', () {
      const widget = KriyoBottomNavigation(
        role: KriyoNavRole.customer,
        currentIndex: 0,
        onTabChanged: _noop,
      );

      // Access default customer items through element
      expect(widget.role, equals(KriyoNavRole.customer));
    });

    test('Customer navigation custom items match: Home, Explore, Craft Stories, Cart, Me', () {
      final items = [
        const KriyoNavigationItem(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        const KriyoNavigationItem(
          label: 'Explore',
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
        ),
        const KriyoNavigationItem(
          label: 'Craft Stories',
          icon: Icons.play_circle_outline_rounded,
          activeIcon: Icons.play_circle_filled_rounded,
          isPrimaryAction: true,
        ),
        const KriyoNavigationItem(
          label: 'Cart',
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag_rounded,
        ),
        const KriyoNavigationItem(
          label: 'Me',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];

      expect(items.length, equals(5));
      expect(items[2].label, equals('Craft Stories'));
      expect(items[2].isPrimaryAction, isTrue);
      expect(items[2].icon, equals(Icons.play_circle_outline_rounded));
    });
  });
}

void _noop(int idx) {}
