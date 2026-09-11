import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/constants/kriyo_icons.dart';
import 'package:kriyo_artisan_app/core/enums/user_role.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_orders_provider.dart';
import 'package:kriyo_artisan_app/features/voice_assistant/models/voice_assistant_state.dart';
import 'package:kriyo_artisan_app/features/voice_assistant/services/voice_intent_service.dart';

void main() {
  group('VoiceIntentService Tests', () {
    late VoiceIntentService service;

    setUp(() {
      service = VoiceIntentService();
    });

    test('Empty audio transcript produces friendly retry prompt', () {
      final res = service.process(
        transcript: '',
        role: UserRole.artisan,
      );

      expect(res.intent, VoiceIntentType.unknown);
      expect(res.confidence, 0.0);
      expect(res.message, contains("didn't hear anything"));
    });

    test('Artisan "What should I do today?" reports real production counts', () {
      final mockOrdersState = ArtisanOrdersState(
        allOrders: [
          ArtisanOrder(
            id: '1',
            customerName: 'Aarav',
            customerLocation: 'Chennai',
            customerPhone: '+91 9876543210',
            items: const [
              ArtisanOrderItem(name: 'Saree', quantity: 1, price: 5000),
            ],
            itemCount: 1,
            totalAmount: 5000,
            status: ArtisanOrderStatus.preparing,
            date: 'Today',
            createdAt: DateTime.now(),
            actionRequired: true,
          ),
          ArtisanOrder(
            id: '2',
            customerName: 'Priya',
            customerLocation: 'Bengaluru',
            customerPhone: '+91 9876543211',
            items: const [
              ArtisanOrderItem(name: 'Shawl', quantity: 1, price: 3500),
            ],
            itemCount: 1,
            totalAmount: 3500,
            status: ArtisanOrderStatus.readyToShip,
            date: 'Yesterday',
            createdAt: DateTime.now(),
          ),
        ],
      );

      final res = service.process(
        transcript: 'What should I do today?',
        role: UserRole.artisan,
        artisanOrdersState: mockOrdersState,
      );

      expect(res.intent, VoiceIntentType.artisanWhatToDoToday);
      expect(res.action, VoiceActionType.viewOrders);
      expect(res.message, contains('1 orders in production'));
      expect(res.message, contains('1 order ready for dispatch'));
      expect(res.suggestedActions.isNotEmpty, true);
    });

    test('Artisan Tamil prompt "இன்று என்ன செய்ய வேண்டும்?" resolves correctly', () {
      final res = service.process(
        transcript: 'இன்று என்ன செய்ய வேண்டும்?',
        role: UserRole.artisan,
        languageCode: 'ta',
      );

      expect(res.intent, VoiceIntentType.artisanWhatToDoToday);
      expect(res.action, VoiceActionType.viewOrders);
      expect(res.message, contains('தயாரிப்பு'));
    });

    test('Customer "Show pottery under 2000" extracts entities and returns search action', () {
      final res = service.process(
        transcript: 'Show pottery under 2000',
        role: UserRole.customer,
      );

      expect(res.intent, VoiceIntentType.customerSearch);
      expect(res.action, VoiceActionType.search);
      expect(res.actionPayload?['query'], 'pottery');
      expect(res.actionPayload?['maxPrice'], 2000.0);
    });

    test('Customer "What\'s in my cart?" returns cart action with item counts', () {
      final res = service.process(
        transcript: "What's in my cart?",
        role: UserRole.customer,
        customerCartItemCount: 3,
      );

      expect(res.intent, VoiceIntentType.customerCart);
      expect(res.action, VoiceActionType.viewCart);
      expect(res.message, contains('3 authentic handcrafted items'));
    });

    test('Customer "Where is my order?" returns tracking action', () {
      final res = service.process(
        transcript: 'Where is my order?',
        role: UserRole.customer,
      );

      expect(res.intent, VoiceIntentType.customerOrders);
      expect(res.action, VoiceActionType.navigate);
      expect(res.message, contains('KRY-10248'));
    });
  });
}
