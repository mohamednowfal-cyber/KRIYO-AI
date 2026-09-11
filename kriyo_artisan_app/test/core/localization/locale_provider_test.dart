import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/core/localization/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleNotifier Tests', () {
    test('Defaults to English locale', () {
      final notifier = LocaleNotifier();
      expect(notifier.state, const Locale('en'));
    });

    test('Sets and persists Tamil locale', () async {
      final notifier = LocaleNotifier();
      await notifier.setLocale(const Locale('ta'));
      expect(notifier.state, const Locale('ta'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('kriyo_app_locale'), 'ta');
      expect(prefs.getBool('kriyo_has_selected_language'), true);
    });

    test('Sets and persists Hindi locale', () async {
      final notifier = LocaleNotifier();
      await notifier.setLocaleCode('hi');
      expect(notifier.state, const Locale('hi'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('kriyo_app_locale'), 'hi');
    });

    test('Falls back to English for unknown locales', () async {
      final notifier = LocaleNotifier();
      await notifier.setLocale(const Locale('fr'));
      expect(notifier.state, const Locale('en'));
    });
  });

  group('AppLocalizations Strings Verification', () {
    test('English translations match expectations', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.home, 'Home');
      expect(l10n.craft, 'Craft');
      expect(l10n.create, 'Create');
      expect(l10n.orders, 'Orders');
      expect(l10n.profile, 'Profile');
      expect(l10n.explore, 'Explore');
      expect(l10n.wishlist, 'Wishlist');
      expect(l10n.cart, 'Cart');
      expect(l10n.me, 'Me');
      expect(l10n.searchOrdersPlaceholder, 'Search orders, customers, products...');
      expect(l10n.noOrdersMatchTitle, 'No Orders Match Your Search');
      expect(l10n.viewAllOrders, 'View All Orders');
    });

    test('Tamil translations match expectations', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ta'));
      expect(l10n.home, 'முகப்பு');
      expect(l10n.craft, 'கைவினை');
      expect(l10n.create, 'உருவாக்கு');
      expect(l10n.orders, 'ஆர்டர்கள்');
      expect(l10n.profile, 'சுயவிவரம்');
      expect(l10n.explore, 'ஆராயுங்கள்');
      expect(l10n.wishlist, 'விருப்பப்பட்டியல்');
      expect(l10n.cart, 'கார்ட்');
      expect(l10n.me, 'என் சுயவிவரம்');
      expect(l10n.searchOrdersPlaceholder, 'ஆர்டர்கள், வாடிக்கையாளர்கள், பொருட்களைத் தேடுங்கள்...');
      expect(l10n.noOrdersMatchTitle, 'உங்கள் தேடலுக்கு ஏற்ற ஆர்டர்கள் இல்லை');
      expect(l10n.viewAllOrders, 'அனைத்து ஆர்டர்களையும் காண்க');
    });

    test('Hindi translations match expectations', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(l10n.home, 'होम');
      expect(l10n.craft, 'शिल्प');
      expect(l10n.create, 'बनाएँ');
      expect(l10n.orders, 'ऑर्डर');
      expect(l10n.profile, 'प्रोफ़ाइल');
      expect(l10n.explore, 'एक्सप्लोर');
      expect(l10n.wishlist, 'विशलिस्ट');
      expect(l10n.cart, 'कार्ट');
      expect(l10n.me, 'मेरी प्रोफ़ाइल');
      expect(l10n.searchOrdersPlaceholder, 'ऑर्डर, ग्राहक, उत्पाद खोजें...');
      expect(l10n.noOrdersMatchTitle, 'आपकी खोज से कोई ऑर्डर मेल नहीं खाता');
      expect(l10n.viewAllOrders, 'सभी ऑर्डर देखें');
    });
  });
}
