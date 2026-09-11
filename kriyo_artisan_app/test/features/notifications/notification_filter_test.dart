import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/features/notifications/presentation/providers/kriyo_notifications_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Kriyo Notifications - Data Isolation & Filtering', () {
    test('Customer notifications contain only customer-specific records', () {
      final notifier = KriyoNotificationsNotifier(UserRole.customer);
      final list = notifier.getFilteredNotifications();

      expect(list.isNotEmpty, isTrue);
      for (final item in list) {
        expect(item.role, equals(UserRole.customer));
      }
    });

    test('Artisan notifications contain only artisan-specific records', () {
      final notifier = KriyoNotificationsNotifier(UserRole.artisan);
      final list = notifier.getFilteredNotifications();

      expect(list.isNotEmpty, isTrue);
      for (final item in list) {
        expect(item.role, equals(UserRole.artisan));
      }
    });

    test('Filtering updates list immediately without side effects', () {
      final notifier = KriyoNotificationsNotifier(UserRole.customer);

      // Default All
      expect(notifier.state.selectedFilter, equals(NotificationCategory.all));
      expect(notifier.getFilteredNotifications().length, equals(4));

      // Filter Orders
      notifier.selectFilter(NotificationCategory.order);
      expect(notifier.state.selectedFilter, equals(NotificationCategory.order));
      final orders = notifier.getFilteredNotifications();
      expect(orders.length, equals(1));
      expect(orders.first.category, equals(NotificationCategory.order));

      // Filter Craft & Heritage
      notifier.selectFilter(NotificationCategory.craftHeritage);
      final craft = notifier.getFilteredNotifications();
      expect(craft.length, equals(2));

      // Filter Payment (none for customer seed)
      notifier.selectFilter(NotificationCategory.payment);
      final payments = notifier.getFilteredNotifications();
      expect(payments.isEmpty, isTrue);
    });

    test('Marking notification as read updates unread status and persists', () async {
      final notifier = KriyoNotificationsNotifier(UserRole.customer);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Initially unread items
      notifier.selectFilter(NotificationCategory.unread);
      final initialUnreads = notifier.getFilteredNotifications();
      expect(initialUnreads.length, equals(2));

      final firstId = initialUnreads.first.id;
      await notifier.markAsRead(firstId);

      // Now unread list should decrease by 1
      final remainingUnreads = notifier.getFilteredNotifications();
      expect(remainingUnreads.length, equals(1));
      expect(remainingUnreads.any((n) => n.id == firstId), isFalse);

      // Check that read id is saved in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('kriyo_read_notifications_customer');
      expect(saved, contains(firstId));
    });
  });
}
