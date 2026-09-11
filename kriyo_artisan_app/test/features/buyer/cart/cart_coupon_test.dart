import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cart Coupon Calculation Tests', () {
    const double subtotal = 16350.0;

    double calculateDiscount(String code, double amount) {
      final normalized = code.trim().toUpperCase();
      switch (normalized) {
        case 'KRIYOHERITAGE':
          return 500.0;
        case 'ARTISAN10':
          return amount * 0.10;
        case 'WELCOME100':
          return 100.0;
        default:
          return 0.0;
      }
    }

    test('Validates KRIYOHERITAGE coupon yields flat ₹500 discount', () {
      final discount = calculateDiscount('kriyoheritage', subtotal);
      expect(discount, equals(500.0));
      expect(subtotal - discount, equals(15850.0));
    });

    test('Validates ARTISAN10 coupon yields 10% discount', () {
      final discount = calculateDiscount('ARTISAN10', subtotal);
      expect(discount, equals(1635.0));
      expect(subtotal - discount, equals(14715.0));
    });

    test('Validates WELCOME100 coupon yields flat ₹100 discount', () {
      final discount = calculateDiscount('welcome100', subtotal);
      expect(discount, equals(100.0));
      expect(subtotal - discount, equals(16250.0));
    });

    test('Rejects invalid coupons', () {
      final discount = calculateDiscount('INVALIDCODE', subtotal);
      expect(discount, equals(0.0));
    });
  });
}
