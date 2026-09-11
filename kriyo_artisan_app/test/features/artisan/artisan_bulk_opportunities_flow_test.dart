import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kriyo_artisan_app/features/artisan/opportunities/providers/artisan_bulk_opportunities_provider.dart';
import 'package:kriyo_artisan_app/features/notifications/presentation/providers/kriyo_notifications_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Artisan Bulk Opportunities Acceptance & Fulfillment Flow', () {
    test('Initial state: Spotlight order is in available and not in accepted', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(artisanBulkOpportunitiesProvider.notifier).loadOpportunities();

      final state = container.read(artisanBulkOpportunitiesProvider);
      expect(state.isLoading, false);
      expect(state.availableOpportunities.any((o) => o.id == 'B2B-KRY-10021'), true);
      expect(state.acceptedOpportunities.any((o) => o.id == 'B2B-KRY-10021'), false);
    });

    test('Accept Opportunity: Moves to accepted, removes from available, and generates notification', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier.loadOpportunities();

      // Accept the opportunity
      final accepted = await notifier.acceptOpportunity(
        orderId: 'B2B-KRY-10021',
        confirmedQuantity: 150,
        leadDays: 18,
        notes: 'Pit loom reserved',
      );

      expect(accepted.id, 'B2B-KRY-10021');
      expect(accepted.confirmedAllocation, 150);
      expect(accepted.status, BulkOpportunityStatus.inProduction);

      final updatedState = container.read(artisanBulkOpportunitiesProvider);
      // Removed from available
      expect(updatedState.availableOpportunities.any((o) => o.id == 'B2B-KRY-10021'), false);
      // Present in accepted
      expect(updatedState.acceptedOpportunities.any((o) => o.id == 'B2B-KRY-10021'), true);

      // Notification is dispatched
      final notifs = container.read(artisanNotificationsProvider.notifier).rawNotifications;
      expect(notifs.any((n) => n.title == 'Bulk Opportunity Accepted'), true);
    });

    test('Duplicate acceptance is prevented', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier.loadOpportunities();

      await notifier.acceptOpportunity(
        orderId: 'B2B-KRY-10021',
        confirmedQuantity: 150,
        leadDays: 18,
      );

      // Attempt second acceptance
      expect(
        () async => await notifier.acceptOpportunity(
          orderId: 'B2B-KRY-10021',
          confirmedQuantity: 150,
          leadDays: 18,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Capacity validation: cannot exceed verified workshop capacity (150 units)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier.loadOpportunities();

      expect(
        () async => await notifier.acceptOpportunity(
          orderId: 'B2B-KRY-10021',
          confirmedQuantity: 250, // exceeds 150
          leadDays: 18,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Production progress safe clamp (never negative, never > allocated)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier.loadOpportunities();

      await notifier.acceptOpportunity(
        orderId: 'B2B-KRY-10021',
        confirmedQuantity: 150,
        leadDays: 18,
      );

      // Update to 60
      await notifier.updateProductionQuantity(
        orderId: 'B2B-KRY-10021',
        completedUnits: 60,
      );
      var opp = container.read(artisanBulkOpportunitiesProvider).acceptedOpportunities.first;
      expect(opp.completedQuantity, 60);
      expect(opp.remainingUnits, 90);
      expect(opp.progressRatio, 60 / 150);

      // Try negative quantity: should clamp to 0
      await notifier.updateProductionQuantity(
        orderId: 'B2B-KRY-10021',
        completedUnits: -25,
      );
      opp = container.read(artisanBulkOpportunitiesProvider).acceptedOpportunities.first;
      expect(opp.completedQuantity, 0);

      // Try quantity exceeding 150: should clamp to 150
      await notifier.updateProductionQuantity(
        orderId: 'B2B-KRY-10021',
        completedUnits: 999,
      );
      opp = container.read(artisanBulkOpportunitiesProvider).acceptedOpportunities.first;
      expect(opp.completedQuantity, 150);
      expect(opp.status, BulkOpportunityStatus.readyForSubmission);
    });

    test('Submission flow: transitions to submitted and prevents duplicate submissions', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier.loadOpportunities();

      await notifier.acceptOpportunity(
        orderId: 'B2B-KRY-10021',
        confirmedQuantity: 150,
        leadDays: 18,
      );

      await notifier.updateProductionQuantity(
        orderId: 'B2B-KRY-10021',
        completedUnits: 150,
      );

      // Submit allocation
      await notifier.submitAllocation(
        orderId: 'B2B-KRY-10021',
        notes: 'GI tag verified and packaged',
        photos: ['loom.jpg', 'gi_tag.jpg'],
      );

      var opp = container.read(artisanBulkOpportunitiesProvider).acceptedOpportunities.first;
      expect(opp.status, BulkOpportunityStatus.submitted);
      expect(opp.submissionPhotos.length, 2);

      // Attempt duplicate submission
      expect(
        () async => await notifier.submitAllocation(
          orderId: 'B2B-KRY-10021',
          notes: 'Second submission',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Persistence across container restart via SharedPreferences', () async {
      // First container accepts opportunity
      final container1 = ProviderContainer();
      final notifier1 = container1.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier1.loadOpportunities();

      await notifier1.acceptOpportunity(
        orderId: 'B2B-KRY-10021',
        confirmedQuantity: 150,
        leadDays: 18,
      );
      await notifier1.updateProductionQuantity(
        orderId: 'B2B-KRY-10021',
        completedUnits: 75,
      );
      container1.dispose();

      // Second container (simulating app restart)
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final notifier2 = container2.read(artisanBulkOpportunitiesProvider.notifier);
      await notifier2.loadOpportunities();

      final state2 = container2.read(artisanBulkOpportunitiesProvider);
      // Still removed from available
      expect(state2.availableOpportunities.any((o) => o.id == 'B2B-KRY-10021'), false);
      // Preserved in accepted with 75 completed
      expect(state2.acceptedOpportunities.any((o) => o.id == 'B2B-KRY-10021'), true);
      final persistedOpp = state2.acceptedOpportunities.firstWhere((o) => o.id == 'B2B-KRY-10021');
      expect(persistedOpp.confirmedAllocation, 150);
      expect(persistedOpp.completedQuantity, 75);
    });
  });
}
