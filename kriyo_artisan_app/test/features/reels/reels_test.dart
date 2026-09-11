import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/reels/models/reel_models.dart';
import 'package:kriyo_artisan_app/features/reels/providers/reels_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Artisan Reels Core Models', () {
    test('ReelVisibility permissions cover public, learners, and private', () {
      expect(ReelVisibility.values.length, equals(3));
      expect(ReelVisibility.publicView.label, equals('Public'));
      expect(ReelVisibility.learnersOnly.label, equals('Learners Only'));
      expect(ReelVisibility.privateArchive.label, equals('Private Archive'));
    });

    test('ArtisanReelItem correctly connects craft technique, product, and Gurukul course', () {
      final reel = ArtisanReelItem(
        id: 'REL-TEST-01',
        artisanId: 'ART-001',
        artisanName: 'Lakshmi Devi',
        artisanRole: '4th Gen Master Weaver',
        artisanAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
        region: 'Kanchipuram, Tamil Nadu',
        videoUrl: 'https://sample-videos.com/video.mp4',
        thumbnailUrl: 'https://images.unsplash.com/thumb.jpg',
        caption: 'Traditional Korvai interlock',
        craftType: 'Handloom Weaving',
        technique: 'Korvai Dual Shuttle',
        linkedProductId: 'KRY-PRD-01',
        linkedCourseId: 'GRK-CRS-01',
        createdAt: DateTime.now(),
      );

      expect(reel.linkedProductId, equals('KRY-PRD-01'));
      expect(reel.linkedCourseId, equals('GRK-CRS-01'));
      expect(reel.craftType, equals('Handloom Weaving'));
    });
  });

  group('Reels StateNotifier Interactions', () {
    late ReelsNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = ReelsNotifier();
    });

    test('Initial state contains published craft reels with linked products and courses', () {
      final state = notifier.state;
      expect(state.publishedReels.length, greaterThanOrEqualTo(3));
      final first = state.publishedReels.first;
      expect(first.linkedProductId, isNotNull);
      expect(first.linkedCourseId, isNotNull);
      expect(first.likesCount, greaterThan(0));
    });

    test('toggleLike updates like status and increments/decrements count', () {
      final reel = notifier.state.publishedReels.first;
      final initialLikes = reel.likesCount;
      final initialLiked = reel.isLiked;

      notifier.toggleLike(reel.id);
      var updated = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updated.isLiked, equals(!initialLiked));
      expect(updated.likesCount, equals(initialLikes + 1));

      notifier.toggleLike(reel.id);
      updated = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updated.isLiked, equals(initialLiked));
      expect(updated.likesCount, equals(initialLikes));
    });

    test('toggleSave updates saved status and increments savesCount', () {
      final reel = notifier.state.publishedReels.first;
      final initialSaves = reel.savesCount;

      notifier.toggleSave(reel.id);
      final updated = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updated.isSaved, isTrue);
      expect(updated.savesCount, equals(initialSaves + 1));
    });

    test('addComment inserts new comment and increments commentsCount', () {
      final reel = notifier.state.publishedReels.first;
      final initialCommentsCount = reel.commentsCount;

      notifier.addComment(reel.id, 'What type of organic dye did you use for the red warp?');

      final updatedReel = notifier.state.publishedReels.firstWhere((r) => r.id == reel.id);
      expect(updatedReel.commentsCount, equals(initialCommentsCount + 1));

      final comments = notifier.state.comments[reel.id];
      expect(comments, isNotNull);
      expect(comments!.first.text, contains('organic dye'));
    });

    test('publishReel adds a new reel to the published feed and clears draft', () async {
      final initialLength = notifier.state.publishedReels.length;
      final newReel = ArtisanReelItem(
        id: 'REL-NEW-99',
        artisanId: 'ART-002',
        artisanName: 'Murugesan Perumal',
        artisanRole: 'Terracotta Sculptor',
        artisanAvatar: 'https://images.unsplash.com/avatar.jpg',
        region: 'Puducherry',
        videoUrl: 'https://sample-videos.com/video.mp4',
        thumbnailUrl: 'https://images.unsplash.com/thumb.jpg',
        caption: 'Centering red clay on the foot wheel',
        craftType: 'Terracotta Pottery',
        technique: 'Foot-Wheel Centering',
        createdAt: DateTime.now(),
      );

      await notifier.publishReel(newReel);

      expect(notifier.state.publishedReels.length, equals(initialLength + 1));
      expect(notifier.state.publishedReels.first.id, equals('REL-NEW-99'));
      expect(notifier.state.activeDraft, isNull);
    });
  });
}
