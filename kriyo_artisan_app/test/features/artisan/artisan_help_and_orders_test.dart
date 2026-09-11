import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/app/config/app_config.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/help/data/artisan_help_repository.dart';
import 'package:kriyo_artisan_app/features/artisan/help/screens/artisan_help_topic_detail_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_customer_issue_detail_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_orders_provider.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_orders_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/artisan_return_detail_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/orders/models/artisan_order_issue_models.dart';
import 'package:kriyo_artisan_app/features/artisan/settings/artisan_support_screen.dart';

Widget createTestApp(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    ),
  );
}

void main() {
  group('Part 1: Artisan Help & Support Tests', () {
    test('Verify AppConfig support phone numbers', () {
      expect(AppConfig.artisanSupportPhone, '+918778658865');
      expect(AppConfig.artisanSupportPhoneDisplay, '+91 87786 58865');
    });

    test('Help Repository returns 6 core topics and handles search query filtering', () {
      final repository = const ArtisanHelpRepository();
      final allTopics = ArtisanHelpRepository.topics;
      expect(allTopics.length, 6);

      // Verify all 6 topic titles are present
      final titles = allTopics.map((t) => t.title).toList();
      expect(titles, contains('Product Upload & Photography'));
      expect(titles, contains('Orders & Shipping Labels'));
      expect(titles, contains('Weekly Bank Payouts'));
      expect(titles, contains('Heritage Vault & Cultural Consent'));
      expect(titles, contains('Artisan Passport Verification'));
      expect(titles, contains('Account & Profile Details'));

      // Filter by 'Photography'
      final photoFiltered = repository.search('Photography');
      expect(photoFiltered.length, 1);
      expect(photoFiltered.first.id, 'product_upload');

      // Filter by non-existent query
      final emptyFiltered = repository.search('xyznonexistent123');
      expect(emptyFiltered, isEmpty);
    });

    testWidgets('Help & Support screen search, typing filter, clear button, and helpline dialer', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ArtisanSupportScreen()));
      await tester.pumpAndSettle();

      // Screen title and Helpline card check
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Artisan Guild Helpline'), findsOneWidget);
      expect(find.text(AppConfig.artisanSupportPhoneDisplay), findsOneWidget);
      expect(find.text('Contact KRIYO Support Helpline'), findsOneWidget);

      // Search bar hint check
      expect(find.text('Search help guides, topics...'), findsOneWidget);

      // Verify all 6 common topics initially visible
      expect(find.text('Product Upload & Photography'), findsOneWidget);
      expect(find.text('Orders & Shipping Labels'), findsOneWidget);
      expect(find.text('Weekly Bank Payouts'), findsOneWidget);

      // Type query: 'Bank'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Bank');
      await tester.pumpAndSettle();

      // 'Weekly Bank Payouts' should still be visible, others filtered out
      expect(find.text('Weekly Bank Payouts'), findsOneWidget);
      expect(find.text('Product Upload & Photography'), findsNothing);

      // Test clear button
      final clearButton = find.byTooltip('Clear search');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All topics restored
      expect(find.text('Product Upload & Photography'), findsOneWidget);

      // Type nonexistent query to check empty state
      await tester.enterText(searchField, 'xyzunknown987');
      await tester.pumpAndSettle();

      expect(find.text('No help topics found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap 'Clear Search' in empty state
      await tester.tap(find.widgetWithText(ElevatedButton, 'Clear Search'));
      await tester.pumpAndSettle();

      // Back to all topics
      expect(find.text('Product Upload & Photography'), findsOneWidget);
    });

    testWidgets('Help Topic Detail Screen displays sections and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ArtisanHelpTopicDetailScreen(topicId: 'product_upload')));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Product Upload & Photography'), findsWidgets);

      // Action button
      expect(find.text('Create Product'), findsOneWidget);

      // Section steps
      expect(find.text('Getting Started: 6-Step Workflow'), findsOneWidget);
      expect(find.text('Recommended Angles for Handicrafts'), findsOneWidget);
    });
  });

  group('Part 2: Artisan Orders Screen, Returns & Issues Tests', () {
    testWidgets('Orders Screen displays horizontal tabs with live counts, returns and issues tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ArtisanOrdersScreen()));
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Orders'), findsOneWidget);

      // Verify Horizontal Tabs exist: All, New, Preparing, Ready, Shipped, Returns, Issues, Completed
      expect(find.text('All'), findsWidgets);
      expect(find.text('New'), findsWidgets);
      expect(find.text('Preparing'), findsWidgets);
      expect(find.text('Ready'), findsWidgets);
      expect(find.text('Shipped'), findsWidgets);
      expect(find.text('Returns'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);

      // Switch tab to Returns
      await tester.tap(find.text('Returns'));
      await tester.pumpAndSettle();

      // Returns tab should display order #KRY-10192 with return details
      expect(find.text('#KRY-10192'), findsOneWidget);
      expect(find.text('Review Return'), findsOneWidget);

      // Switch tab to Issues
      await tester.tap(find.text('Issues'));
      await tester.pumpAndSettle();

      // Issues tab should display customer issues with 'View Issue' CTA
      expect(find.text('View Issue'), findsWidgets);
    });

    testWidgets('Artisan Return Detail Screen displays order details and performs return actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ArtisanReturnDetailScreen(orderId: 'KRY-10192')));
      await tester.pumpAndSettle();

      // Title & order ID
      expect(find.text('Return Request'), findsOneWidget);
      expect(find.text('Order #KRY-10192'), findsOneWidget);

      // Customer message and return reason
      expect(find.textContaining('Product damaged during courier transit'), findsOneWidget);
      expect(find.text('Customer Message'), findsOneWidget);

      // Action buttons
      expect(find.text('Accept Return'), findsOneWidget);
      expect(find.text('Request More Information'), findsOneWidget);

      // Tap Accept Return -> updates status and shows SnackBar
      await tester.tap(find.text('Accept Return'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Return Request Accepted'), findsOneWidget);
      expect(find.text('Approved'), findsWidgets);

      // Tap Request More Information -> opens dialog
      await tester.tap(find.text('Request More Information'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Specify what details or photos you need'), findsOneWidget);
    });

    testWidgets('Artisan Customer Issue Detail Screen allows message reply and status resolution', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ArtisanCustomerIssueDetailScreen(orderId: 'KRY-10248')));
      await tester.pumpAndSettle();

      // Header & details
      expect(find.text('Customer Issue'), findsOneWidget);
      expect(find.text('Order #KRY-10248'), findsOneWidget);
      expect(find.text('High Priority'), findsOneWidget);
      expect(find.text('Production Update Required'), findsOneWidget);

      // Compose response
      final replyField = find.byType(TextField);
      expect(replyField, findsOneWidget);
      await tester.enterText(replyField, 'We have dispatched the natural dye sample for you to review.');
      await tester.pumpAndSettle();

      // Send response
      final sendButton = find.widgetWithText(ElevatedButton, 'Send Response');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify new message appeared in discussion thread
      expect(find.text('We have dispatched the natural dye sample for you to review.'), findsOneWidget);

      // Test Resolve Issue action button
      final resolveButton = find.text('Resolve Issue');
      expect(resolveButton, findsOneWidget);
      await tester.tap(resolveButton);
      await tester.pumpAndSettle();

      // Status updated to Resolved
      expect(find.text('Resolved'), findsWidgets);
    });
  });
}
