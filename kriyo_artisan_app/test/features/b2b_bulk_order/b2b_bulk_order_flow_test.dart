import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/models/bulk_order_models.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/artisan/screens/artisan_b2b_production_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/artisan/screens/artisan_bulk_request_detail_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/artisan/screens/artisan_contribution_history_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/screens/ai_capacity_matching_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/screens/bulk_order_request_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/screens/bulk_order_tracking_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/screens/craft_capacity_graph_screen.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/widgets/artisan_match_card.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/widgets/craft_capacity_graph_widget.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/presentation/customer/widgets/team_production_progress_widget.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/providers/bulk_order_provider.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/repository/bulk_order_repository.dart';
import 'package:kriyo_artisan_app/features/b2b_bulk_order/services/ai_capacity_matching_service.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('AI Capacity Matching Service Tests', () {
    test('Calculates multi-factor compatibility score correctly', () {
      const candidate = ArtisanCapacityCandidate(
        artisanId: 'ART-TEST-01',
        name: 'Master Weaver',
        craftSpecialty: 'Traditional Handloom Weaving',
        location: 'Kanchipuram, TN',
        isVerified: true,
        technique: 'Pit Loom / Korvai',
        currentInventoryStock: 5,
        confirmedProductionCapacity: 150,
        leadTimeDays: 18,
        unitPrice: 1200.0,
        heritageScore: 0.95,
      );

      final score = AiCapacityMatchingService.calculateCompatibilityScore(
        candidate: candidate,
        craftCategory: 'Handloom & Traditional Weaving',
        preferredMaterials: 'Handloom Cotton, Natural Dye',
        availableDays: 30,
      );

      expect(score, greaterThanOrEqualTo(85));
      expect(score, lessThanOrEqualTo(99));
    });

    test('Separates stock from production capacity and allocates 1,000 units', () {
      final team = AiCapacityMatchingService.assembleCraftTeam(
        bulkOrderId: 'B2B-TEST-01',
        requiredQuantity: 1000,
        craftCategory: 'Handloom & Traditional Weaving',
        preferredMaterials: 'Handloom Cotton, Natural Dye',
        deliveryDate: DateTime.now().add(const Duration(days: 35)),
      );

      expect(team.members.length, equals(5));
      expect(team.allocatedQuantity, equals(1000));
      expect(team.members[0].allocatedQuantity, equals(150));
      expect(team.members[1].allocatedQuantity, equals(250));
      expect(team.members[2].allocatedQuantity, equals(200));
      expect(team.members[3].allocatedQuantity, equals(180));
      expect(team.members[4].allocatedQuantity, equals(220));
    });

    test('AI Team Rebalancing finds replacements when shortfall occurs', () {
      final replacements = AiCapacityMatchingService.findReplacementArtisans(
        teamId: 'TEAM-TEST-01',
        shortfallQuantity: 200,
        craftCategory: 'Handloom & Traditional Weaving',
        preferredMaterials: 'Handloom Cotton',
        deliveryDate: DateTime.now().add(const Duration(days: 30)),
        existingArtisanIds: ['ART-M-01', 'ART-M-02', 'ART-M-03', 'ART-M-04', 'ART-M-05'],
      );

      expect(replacements.isNotEmpty, isTrue);
      final replacedQty = replacements.fold(0, (sum, r) => sum + r.allocatedQuantity);
      expect(replacedQty, equals(200)); // 120 (Artisan F) + 80 (Artisan G) = 200
    });
  });

  group('Repository & Riverpod Provider Tests', () {
    test('MockBulkOrderRepository returns seeded B2B order and craft team', () async {
      final repo = MockBulkOrderRepository();
      final order = await repo.getRequest('B2B-KRY-10021');
      final team = await repo.getCraftTeam('B2B-KRY-10021');

      expect(order, isNotNull);
      expect(order!.quantityRequired, equals(1000));
      expect(team, isNotNull);
      expect(team!.members.length, equals(5));
      expect(team.completedQuantity, equals(550));
    });

    test('Artisan response updates confirmed capacity and status', () async {
      final repo = MockBulkOrderRepository();
      final updatedTeam = await repo.artisanRespond(
        orderId: 'B2B-KRY-10021',
        artisanId: 'ART-M-05',
        accept: true,
        confirmedQuantity: 220,
        leadDays: 20,
        notes: 'Warping ready',
      );

      final m5 = updatedTeam.members.firstWhere((m) => m.artisanId == 'ART-M-05');
      expect(m5.status, equals(CraftMemberStatus.accepted));
      expect(m5.confirmedQuantity, equals(220));
      expect(m5.productionNotes, equals('Warping ready'));
    });

    test('Artisan production update increments completed units and overall progress', () async {
      final repo = MockBulkOrderRepository();
      final updatedTeam = await repo.updateArtisanProduction(
        orderId: 'B2B-KRY-10021',
        artisanId: 'ART-M-02',
        completedUnits: 150,
        stage: 'Producing',
        notes: 'Added 30 sarees today',
      );

      final m2 = updatedTeam.members.firstWhere((m) => m.artisanId == 'ART-M-02');
      expect(m2.completedQuantity, equals(150));
      expect(updatedTeam.completedQuantity, equals(580)); // 550 + 30 = 580
    });
  });

  group('Customer B2B Widgets & Screens Tests', () {
    testWidgets('CraftCapacityGraphWidget renders requirement root node, artisan nodes, and capacity', (tester) async {
      final repo = MockBulkOrderRepository();
      final team = (await repo.getCraftTeam('B2B-KRY-10021'))!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CraftCapacityGraphWidget(team: team),
            ),
          ),
        ),
      );

      expect(find.text('AI CAPACITY GRAPH'), findsOneWidget);
      expect(find.text('1000 UNITS'), findsOneWidget);
      expect(find.text('Anandhi'), findsOneWidget);
      expect(find.text('150 units'), findsOneWidget);
      expect(find.text('Ramanathan'), findsOneWidget);
      expect(find.text('250 units'), findsOneWidget);
    });

    testWidgets('ArtisanMatchCard displays craft details, capacity, and verified status', (tester) async {
      const member = CraftTeamMember(
        id: 'MEM-01',
        craftTeamId: 'TEAM-01',
        artisanId: 'ART-M-01',
        artisanName: 'Anandhi Meenakshi',
        craftSpecialty: 'Traditional Handloom Weaving',
        location: 'Kanchipuram, Tamil Nadu',
        isVerified: true,
        technique: 'Pit Loom / Korvai',
        allocatedQuantity: 150,
        compatibilityScore: 96,
        estimatedDays: 18,
        unitPrice: 1250.0,
        earnings: 178125.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArtisanMatchCard(member: member),
            ),
          ),
        ),
      );

      expect(find.text('Anandhi Meenakshi'), findsOneWidget);
      expect(find.text('✓ KRIYO Verified Artisan'), findsOneWidget);
      expect(find.text('96% Match'), findsOneWidget);
      expect(find.text('Pit Loom / Korvai'), findsOneWidget);
      expect(find.text('150 units'), findsOneWidget);
    });

    testWidgets('TeamProductionProgressWidget renders individual workshop velocity', (tester) async {
      final repo = MockBulkOrderRepository();
      final team = (await repo.getCraftTeam('B2B-KRY-10021'))!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeamProductionProgressWidget(team: team),
            ),
          ),
        ),
      );

      expect(find.text('Overall Production'), findsOneWidget);
      expect(find.text('550 / 1000 Units'), findsOneWidget);
      expect(find.text('55% Completed'), findsOneWidget);
      expect(find.text('Artisan Workshop Velocity'), findsOneWidget);
    });

    testWidgets('BulkOrderRequestScreen validates form and toggles review summary', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BulkOrderRequestScreen(),
          ),
        ),
      );

      expect(find.text('Request a Bulk Order'), findsOneWidget);
      expect(find.text('2. Quantity Required (Units)'), findsOneWidget);

      // Scroll to button and tap
      final reviewBtn = find.text('Review Bulk Order Request');
      await tester.ensureVisible(reviewBtn);
      await tester.pumpAndSettle();
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      expect(find.text('Review Bulk Order Request'), findsOneWidget);
      expect(find.text('Find Artisan Capacity'), findsOneWidget);
      expect(find.textContaining('Pricing Note:'), findsOneWidget);
    });

    testWidgets('AiCapacityMatchingScreen renders smooth progress checkpoints', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiCapacityMatchingScreen(orderId: 'B2B-KRY-10021'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Finding the Right Craft Team'), findsOneWidget);
      expect(find.textContaining('Craft Compatibility'), findsOneWidget);
    });

    testWidgets('CraftCapacityGraphScreen renders capacity graph and send request CTA', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CraftCapacityGraphScreen(orderId: 'B2B-KRY-10021'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Craft Capacity Match'), findsOneWidget);
      expect(find.text('Your KRIYO Craft Team'), findsOneWidget);
      expect(find.textContaining('Send Bulk Order Request'), findsOneWidget);
    });

    testWidgets('BulkOrderTrackingScreen renders live team progress and timeline', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BulkOrderTrackingScreen(orderId: 'B2B-KRY-10021'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bulk Order: B2B-KRY-10021'), findsOneWidget);
      expect(find.text('PRODUCTION IN PROGRESS'), findsOneWidget);
      expect(find.text('Bulk Order Timeline'), findsOneWidget);
      expect(find.text('Team Quality Review'), findsOneWidget);
      expect(find.text('Team Updates & Transparency'), findsOneWidget);
    });
  });

  group('Artisan B2B Screens Tests', () {
    testWidgets('ArtisanBulkRequestDetailScreen renders earnings and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanBulkRequestDetailScreen(orderId: 'B2B-KRY-10021', artisanId: 'ART-M-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('B2B Craft Opportunity'), findsOneWidget);
      expect(find.text('YOUR SUGGESTED ALLOCATION'), findsOneWidget);
      expect(find.text('150 Units'), findsOneWidget);
      expect(find.text('Accept & Confirm Production Capacity'), findsOneWidget);
      expect(find.text('Decline Opportunity'), findsOneWidget);
    });

    testWidgets('ArtisanB2bProductionScreen renders personal allocation and status stages', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanB2bProductionScreen(orderId: 'B2B-KRY-10021', artisanId: 'ART-M-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workshop Production: B2B-KRY-10021'), findsOneWidget);
      expect(find.text('Your Workshop Allocation'), findsOneWidget);
      expect(find.text('Production Status Stages'), findsOneWidget);
      expect(find.text('Update Workshop Production'), findsOneWidget);
    });

    testWidgets('ArtisanContributionHistoryScreen renders past completed orders', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArtisanContributionHistoryScreen(artisanId: 'ART-M-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('B2B Craft Contributions'), findsOneWidget);
      expect(find.text('2 B2B Bulk Orders Completed'), findsOneWidget);
      expect(find.text('B2B-KRY-09884'), findsOneWidget);
      expect(find.text('Handloom Cotton Stoles (500 units)'), findsOneWidget);
    });
  });
}
