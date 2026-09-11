import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/artisan_profile_provider.dart';
import 'package:kriyo_artisan_app/features/artisan/profile/artisan_profile_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/home/artisan_home_screen.dart';
import 'package:kriyo_artisan_app/features/authentication/artisan/screens/artisan_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Artisan Login & Profile User-Filled Details Tests', () {
    testWidgets('ArtisanLoginScreen mobile number field is empty by default even when last phone was saved in prefs',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'last_entered_artisan_phone': '9840123456',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final TextField textField = tester.widget(textFieldFinder);
      // Must be empty so the artisan can fill their mobile number
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('ArtisanProfileScreen displays user-filled details instead of hardcoded defaults',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-set user-entered details from Artisan SignUp & profile setup
      SharedPreferences.setMockInitialValues({
        'kriyo_artisan_name': 'Ramesh Kumar',
        'kriyo_mobile_number': '+91 91234 56789',
        'kriyo_craft_type': 'Clay Pottery & Terracotta',
        'kriyo_district': 'Thanjavur',
        'kriyo_city_or_village': 'Kumbakonam',
        'kriyo_region': 'Kumbakonam, Thanjavur, Tamil Nadu',
        'kriyo_craft_experience': '15',
        'kriyo_preferred_language': 'Tamil (தமிழ்)',
        'kriyo_artisan_aadhaar_masked': '•••• •••• 9876',
        'kriyo_has_artisan_profile': true,
      });

      final container = ProviderContainer();
      // Initialize state with filled details
      container.read(sessionProvider.notifier).completeArtisanProfile(
            name: 'Ramesh Kumar',
            craftType: 'Clay Pottery & Terracotta',
            region: 'Kumbakonam, Thanjavur, Tamil Nadu',
            districtName: 'Thanjavur',
            townOrVillage: 'Kumbakonam',
            yearsOfExperience: '15',
            preferredLanguage: 'Tamil (தமிழ்)',
            aadhaarNumber: '123456789876',
          );
      await container.read(artisanProfileProvider.notifier).updateAllArtisanDetails(
            name: 'Ramesh Kumar',
            mobile: '+91 91234 56789',
            craftSpecialty: 'Clay Pottery & Terracotta',
            region: 'Kumbakonam, Thanjavur, Tamil Nadu',
            district: 'Thanjavur',
            village: 'Kumbakonam',
            experience: '15 Years',
            languages: 'Tamil (தமிழ்)',
            aadhaarNumber: '123456789876',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ArtisanProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the user-entered name is displayed (NOT 'Lakshmi Narayanan')
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Lakshmi Narayanan'), findsNothing);

      // Verify craft specialty and location
      expect(find.textContaining('Clay Pottery & Terracotta'), findsWidgets);
      expect(find.textContaining('Kumbakonam'), findsWidgets);
      expect(find.textContaining('Traditional Handloom'), findsNothing);

      // Verify filled details grid
      expect(find.text('+91 91234 56789'), findsOneWidget);
      expect(find.text('15 Years'), findsOneWidget);
      expect(find.text('•••• •••• 9876'), findsOneWidget);
      expect(find.text('Tamil (தமிழ்)'), findsOneWidget);
    });

    testWidgets('ArtisanHomeScreen greeting reflects user-filled name and craft specialty',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      container.read(sessionProvider.notifier).completeArtisanProfile(
            name: 'Meenakshi Sundaram',
            craftType: 'Brass & Metal Craft',
            region: 'Madurai, Tamil Nadu',
          );
      await container.read(artisanProfileProvider.notifier).updateAllArtisanDetails(
            name: 'Meenakshi Sundaram',
            craftSpecialty: 'Brass & Metal Craft',
            region: 'Madurai, Tamil Nadu',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ArtisanHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Meenakshi'), findsOneWidget);
      expect(find.textContaining('Brass & Metal Craft'), findsOneWidget);
      expect(find.textContaining('Madurai'), findsOneWidget);
    });
  });
}
