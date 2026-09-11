import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/buyer/payment/services/payment_service.dart';

void main() {
  group('PaymentService Unit Tests', () {
    test('isValidUpiId correctly validates Indian UPI VPAs', () {
      expect(PaymentService.isValidUpiId('priya@okhdfcbank'), isTrue);
      expect(PaymentService.isValidUpiId('artisan108@paytm'), isTrue);
      expect(PaymentService.isValidUpiId('user.name@axisbank'), isTrue);
      expect(PaymentService.isValidUpiId('kriyo-craft@upi'), isTrue);

      // Invalid VPAs
      expect(PaymentService.isValidUpiId(''), isFalse);
      expect(PaymentService.isValidUpiId('invalidupi'), isFalse);
      expect(PaymentService.isValidUpiId('user@'), isFalse);
      expect(PaymentService.isValidUpiId('@okhdfcbank'), isFalse);
    });

    test('isValidCardNumber verifies 16-digit card using Luhn algorithm', () {
      // Valid Luhn test numbers
      expect(PaymentService.isValidCardNumber('4532015112830366'), isTrue);
      expect(PaymentService.isValidCardNumber('4532 0151 1283 0366'), isTrue);

      // Invalid lengths or Luhn failures
      expect(PaymentService.isValidCardNumber('1234'), isFalse);
      expect(PaymentService.isValidCardNumber('4532015112830367'), isFalse);
      expect(PaymentService.isValidCardNumber(''), isFalse);
      expect(PaymentService.isValidCardNumber('abcd efgh ijkl mnop'), isFalse);
    });

    test('isValidExpiry correctly checks MM/YY future format', () {
      expect(PaymentService.isValidExpiry('12/28'), isTrue);
      expect(PaymentService.isValidExpiry('05/30'), isTrue);

      // Invalid month
      expect(PaymentService.isValidExpiry('13/28'), isFalse);
      expect(PaymentService.isValidExpiry('00/28'), isFalse);

      // Past date (assuming current year is 2026)
      expect(PaymentService.isValidExpiry('01/20'), isFalse);

      // Malformed
      expect(PaymentService.isValidExpiry('1228'), isFalse);
      expect(PaymentService.isValidExpiry(''), isFalse);
    });

    test('isValidCvv validates 3 or 4 digit security codes', () {
      expect(PaymentService.isValidCvv('123'), isTrue);
      expect(PaymentService.isValidCvv('4567'), isTrue);

      expect(PaymentService.isValidCvv('12'), isFalse);
      expect(PaymentService.isValidCvv('12345'), isFalse);
      expect(PaymentService.isValidCvv('abc'), isFalse);
      expect(PaymentService.isValidCvv(''), isFalse);
    });

    test('generateOrderId produces valid KRY-XXXXX pattern', () {
      final orderId = PaymentService.generateOrderId();
      expect(orderId.startsWith('KRY-'), isTrue);
      expect(orderId.length, equals(9));
    });

    test('processPayment returns success PaymentResult with transaction details', () async {
      final result = await PaymentService.instance.processPayment(
        method: PaymentMethodType.upi,
        amount: 16350,
      );

      expect(result.isSuccess, isTrue);
      expect(result.orderId.startsWith('KRY-'), isTrue);
      expect(result.amount, equals(16350));
      expect(result.method, equals(PaymentMethodType.upi));
      expect(result.transactionId, isNotNull);
    });
  });
}
