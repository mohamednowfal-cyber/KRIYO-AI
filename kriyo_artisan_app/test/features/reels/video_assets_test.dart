import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final videoAssets = [
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

  test('Verify all 10 video assets are registered and readable via rootBundle', () async {
    for (final path in videoAssets) {
      final byteData = await rootBundle.load(path);
      expect(byteData.lengthInBytes, greaterThan(100000), reason: 'Failed for $path');
    }
  });
}
