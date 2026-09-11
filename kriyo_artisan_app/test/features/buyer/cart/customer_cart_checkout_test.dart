import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/core/session/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Address Model & Serialization Tests', () {
    test('CustomerAddress toMap and fromMap works symmetrically', () {
      const address = CustomerAddress(
        id: 'addr_test_1',
        tag: 'Home',
        name: 'Aarav Sharma',
        phone: '9876543210',
        address: 'Flat 402, Lotus Heights, 12th Main, HAL 2nd Stage, Bengaluru Urban',
        city: 'Bengaluru, Karnataka - 560038',
        isDefault: true,
      );

      final map = address.toMap();
      final revived = CustomerAddress.fromMap(map);

      expect(revived.id, equals('addr_test_1'));
      expect(revived.tag, equals('Home'));
      expect(revived.label, equals('Home'));
      expect(revived.name, equals('Aarav Sharma'));
      expect(revived.recipientName, equals('Aarav Sharma'));
      expect(revived.phone, equals('9876543210'));
      expect(revived.address, contains('Lotus Heights'));
      expect(revived.city, contains('Bengaluru'));
      expect(revived.isDefault, isTrue);

      expect(
        revived.fullAddressDisplay,
        contains('Flat 402, Lotus Heights, 12th Main, HAL 2nd Stage, Bengaluru Urban, Bengaluru, Karnataka - 560038'),
      );

      final displayMap = revived.toDisplayMap();
      expect(displayMap['name'], equals('Aarav Sharma'));
      expect(displayMap['phone'], equals('9876543210'));
      expect(displayMap['address'], contains('Lotus Heights'));
      expect(displayMap['type'], equals('Home'));
    });
  });

  group('SessionNotifier Address Management & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default addresses when storage is empty', () async {
      final sessionNotifier = SessionNotifier();
      await sessionNotifier.loadFromStorage();

      expect(sessionNotifier.state.savedAddresses.isNotEmpty, isTrue);
      expect(sessionNotifier.state.selectedAddress, isNotNull);
      expect(sessionNotifier.state.selectedAddress?.tag, equals('Home'));
    });

    test('addAddress appends address and sets it as active selectedAddress', () async {
      final sessionNotifier = SessionNotifier();
      await sessionNotifier.loadFromStorage();
      final initialCount = sessionNotifier.state.savedAddresses.length;

      final newAddr = CustomerAddress(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        tag: 'Work',
        name: 'Priya Patel',
        phone: '9123456780',
        address: 'Suite 800, Tech Park, Whitefield',
        city: 'Bengaluru, Karnataka - 560066',
      );

      sessionNotifier.addAddress(newAddr);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sessionNotifier.state.savedAddresses.length, equals(initialCount + 1));
      expect(sessionNotifier.state.selectedAddress?.name, equals('Priya Patel'));
      expect(sessionNotifier.state.selectedAddress?.tag, equals('Work'));
      expect(sessionNotifier.state.selectedAddress?.city, contains('560066'));

      // Verify persistence to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedJsonList = prefs.getStringList('kriyo_saved_addresses');
      expect(storedJsonList, isNotNull);
      expect(storedJsonList!.length, equals(initialCount + 1));

      final lastJson = jsonDecode(storedJsonList.last) as Map<String, dynamic>;
      expect(lastJson['name'], equals('Priya Patel'));
      expect(lastJson['tag'], equals('Work'));
    });

    test('selectAddress switches active delivery address without losing addresses', () async {
      final sessionNotifier = SessionNotifier();
      await sessionNotifier.loadFromStorage();

      expect(sessionNotifier.state.savedAddresses.length, greaterThanOrEqualTo(2));
      sessionNotifier.selectAddress(1);
      expect(sessionNotifier.state.selectedAddressIndex, equals(1));
      expect(sessionNotifier.state.selectedAddress, equals(sessionNotifier.state.savedAddresses[1]));
    });
  });

  group('Dynamic Cart & Checkout Calculations Tests', () {
    test('Calculates cart subtotal, delivery fee, artisan fund, and total dynamically', () {
      final items = [
        {'title': 'Handmade Silk Saree', 'price': 3500.0, 'quantity': 2},
        {'title': 'Brass Diya Lamp', 'price': 850.0, 'quantity': 3},
      ];

      double calculateSubtotal(List<Map<String, dynamic>> cart) {
        return cart.fold(
          0.0,
          (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int)),
        );
      }

      double subtotal = calculateSubtotal(items);
      // (3500 * 2) + (850 * 3) = 7000 + 2550 = 9550
      expect(subtotal, equals(9550.0));

      double deliveryFee = subtotal >= 999 ? 0.0 : 99.0;
      double artisanFund = 49.0;
      double discount = 500.0; // e.g. KRIYOHERITAGE
      double total = subtotal + deliveryFee + artisanFund - discount;

      expect(deliveryFee, equals(0.0));
      expect(total, equals(9099.0));

      // Test quantity increment and decrement
      items[0]['quantity'] = 3; // +1 Saree -> +3500
      subtotal = calculateSubtotal(items);
      expect(subtotal, equals(13050.0));
      total = subtotal + deliveryFee + artisanFund - discount;
      expect(total, equals(12599.0));

      items[1]['quantity'] = 1; // -2 Diyas -> -1700
      subtotal = calculateSubtotal(items);
      expect(subtotal, equals(11350.0));
      total = subtotal + deliveryFee + artisanFund - discount;
      expect(total, equals(10899.0));
    });
  });

  group('Form Validation Logic Tests for Add Address', () {
    test('Validates phone number strictly to 10 digits', () {
      bool isValidPhone(String? val) {
        if (val == null || val.trim().isEmpty) return false;
        final clean = val.replaceAll(RegExp(r'[\s\-]'), '');
        return RegExp(r'^[6-9]\d{9}$').hasMatch(clean);
      }

      expect(isValidPhone('9876543210'), isTrue);
      expect(isValidPhone('8123456789'), isTrue);
      expect(isValidPhone('7000000000'), isTrue);
      expect(isValidPhone('6999999999'), isTrue);
      expect(isValidPhone('1234567890'), isFalse); // Does not start with 6-9
      expect(isValidPhone('987654321'), isFalse); // 9 digits
      expect(isValidPhone('98765432100'), isFalse); // 11 digits
      expect(isValidPhone('abcdefghij'), isFalse);
    });

    test('Validates PIN code strictly to 6 digits', () {
      bool isValidPincode(String? val) {
        if (val == null || val.trim().isEmpty) return false;
        return RegExp(r'^[1-9][0-9]{5}$').hasMatch(val.trim());
      }

      expect(isValidPincode('560001'), isTrue);
      expect(isValidPincode('110001'), isTrue);
      expect(isValidPincode('600028'), isTrue);
      expect(isValidPincode('060001'), isFalse); // Starts with 0
      expect(isValidPincode('56000'), isFalse); // 5 digits
      expect(isValidPincode('5600001'), isFalse); // 7 digits
      expect(isValidPincode('56000A'), isFalse);
    });
  });
}
