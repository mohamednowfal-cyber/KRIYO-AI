import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kriyo_artisan_app/app/localization/app_localizations.dart';
import 'package:kriyo_artisan_app/features/artisan/products/ai_catalog_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/products/ai_product_photo_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/products/product_capture_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/products/product_published_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/products/product_voice_description_screen.dart';
import 'package:kriyo_artisan_app/features/artisan/products/providers/product_creation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductCreationNotifier Unit Tests', () {
    test('Initial session starts empty without fabricated data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final session = container.read(productCreationProvider);
      expect(session.photos, isEmpty);
      expect(session.description, isEmpty);
      expect(session.title, isEmpty);
      expect(session.material, isEmpty);
      expect(session.technique, isEmpty);
      expect(session.craftCategory, isEmpty);
      expect(session.tags, isEmpty);
      expect(session.isDeployed, isFalse);
    });

    test('Adding first photo assigns Primary role, subsequent photos get Angle role', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productCreationProvider.notifier);
      notifier.addPhoto(File('test_photo_1.jpg'));

      var session = container.read(productCreationProvider);
      expect(session.photos.length, 1);
      expect(session.photos.first.role, 'Primary');

      notifier.addPhoto(File('test_photo_2.jpg'));
      session = container.read(productCreationProvider);
      expect(session.photos.length, 2);
      expect(session.photos[1].role, 'Angle 2');
    });

    test('Setting primary photo reorders roles correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productCreationProvider.notifier);
      notifier.addPhoto(File('photo_1.jpg'));
      notifier.addPhoto(File('photo_2.jpg'));

      // Make photo 2 primary
      notifier.setPrimaryPhoto(1);

      final session = container.read(productCreationProvider);
      expect(session.photos.first.path, 'photo_2.jpg');
      expect(session.photos.first.role, 'Primary');
      expect(session.photos[1].path, 'photo_1.jpg');
      expect(session.photos[1].role, 'Angle 2');
    });

    test('Removing photo readjusts list and roles', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productCreationProvider.notifier);
      notifier.addPhoto(File('photo_1.jpg'));
      notifier.addPhoto(File('photo_2.jpg'));
      notifier.addPhoto(File('photo_3.jpg'));

      notifier.removePhoto(0);

      final session = container.read(productCreationProvider);
      expect(session.photos.length, 2);
      expect(session.photos.first.role, 'Primary');
      expect(session.photos.first.path, 'photo_2.jpg');
    });

    test('Tags can be added and removed dynamically', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productCreationProvider.notifier);
      notifier.addTag('Handloom');
      notifier.addTag('Organic');

      var session = container.read(productCreationProvider);
      expect(session.tags, containsAll(['Handloom', 'Organic']));

      notifier.removeTag('Organic');
      session = container.read(productCreationProvider);
      expect(session.tags, equals(['Handloom']));
    });

    test('markDeployed publishes product to catalog and clearSession resets state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productCreationProvider.notifier);
      notifier.setCatalogDetails(
        title: 'New Silk Saree',
        craftCategory: 'Handloom',
      );
      notifier.setPrice(3200);
      notifier.markDeployed();

      final publishedList = container.read(publishedProductsListProvider);
      expect(publishedList.first['title'], 'New Silk Saree');
      expect(publishedList.first['price'], '₹3200');

      notifier.clearSession();
      final session = container.read(productCreationProvider);
      expect(session.title, isEmpty);
      expect(session.photos, isEmpty);
    });
  });

  group('Step 1 — ProductCaptureScreen Widget Tests', () {
    Widget buildCaptureScreen(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ProductCaptureScreen(),
        ),
      );
    }

    testWidgets('renders capture options and separate Add More Angles button', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildCaptureScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('+ Add More Angles / Details'), findsOneWidget);
      expect(find.text('Continue to AI Quality Check'), findsOneWidget);
    });

    testWidgets('empty state blocks continuation and displays error message', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildCaptureScreen(container));
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue to AI Quality Check');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add at least one product photo to continue.'), findsOneWidget);
    });

    testWidgets('displays photo thumbnail and role badge when photos exist', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(productCreationProvider.notifier).addPhoto(File('sample_test.jpg'));

      await tester.pumpWidget(buildCaptureScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Captured Photos (1)'), findsOneWidget);
    });
  });

  group('Step 2 — AiProductPhotoScreen Widget Tests', () {
    Widget buildStudioScreen(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AiProductPhotoScreen(),
        ),
      );
    }

    testWidgets('renders high contrast Original vs AI Enhanced toggle tabs', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(productCreationProvider.notifier).addPhoto(File('sample.jpg'));

      await tester.pumpWidget(buildStudioScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('Original'), findsOneWidget);
      expect(find.text('AI Enhanced'), findsOneWidget);
      expect(find.text('AI Studio Enhanced Background'), findsOneWidget);

      // Tap Original tab
      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(container.read(productCreationProvider).showEnhanced, isFalse);
    });
  });

  group('Step 3 — ProductVoiceDescriptionScreen Widget Tests', () {
    Widget buildVoiceScreen(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ProductVoiceDescriptionScreen(),
        ),
      );
    }

    testWidgets('starts with empty text and allows artisan typing and recording controls', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildVoiceScreen(container));
      await tester.pumpAndSettle();

      // Description textfield starts empty
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(find.text('Tell KRIYO About This Product'), findsOneWidget);

      // Type manual description
      await tester.enterText(textField, 'Crafted with organic terracotta clay from river bed.');
      await tester.pumpAndSettle();

      expect(container.read(productCreationProvider).description, 'Crafted with organic terracotta clay from river bed.');

      // Recording button is visible
      expect(find.text('Tap to Record Voice'), findsOneWidget);
      expect(find.text('Continue to AI Catalog Generation'), findsOneWidget);
    });
  });

  group('Step 4 — AiCatalogScreen Widget Tests', () {
    Widget buildCatalogScreenWithRouter(ProviderContainer container) {
      final router = GoRouter(
        initialLocation: '/ai-catalog',
        routes: [
          GoRoute(
            path: '/ai-catalog',
            builder: (context, state) => const AiCatalogScreen(),
          ),
          GoRoute(
            path: '/ai-pricing',
            builder: (context, state) => const Scaffold(body: Text('AI Pricing Step 5')),
          ),
        ],
      );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
    }

    testWidgets('renders all editable metadata fields and handles tags', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(productCreationProvider.notifier).setCatalogDetails(
        title: 'Handloom Cotton Scarf',
        material: 'Organic Cotton',
        technique: 'Pit Loom',
        craftCategory: 'Textiles',
        region: 'Kanchipuram',
        tags: ['Eco-friendly', 'Handmade'],
      );

      await tester.pumpWidget(buildCatalogScreenWithRouter(container));
      await tester.pumpAndSettle();

      // Form labels
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('Technique'), findsOneWidget);
      expect(find.text('Craft Category'), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('Generated Tags'), findsOneWidget);

      // Existing tags
      expect(find.text('Eco-friendly'), findsOneWidget);
      expect(find.text('Handmade'), findsOneWidget);

      // Continue CTA
      expect(find.text('Accept & Price'), findsOneWidget);
    });

    testWidgets('empty Step 4 fields trigger validation errors and prevent navigation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildCatalogScreenWithRouter(container));
      await tester.pumpAndSettle();

      // Tap Accept & Price with all fields empty
      await tester.ensureVisible(find.text('Accept & Price'));
      await tester.tap(find.text('Accept & Price'));
      await tester.pumpAndSettle();

      // Check all validation error messages
      expect(find.text('Please enter a product title.'), findsOneWidget);
      expect(find.text('Please enter the material used to make this product.'), findsOneWidget);
      expect(find.text('Please enter the craft technique.'), findsOneWidget);
      expect(find.text('Please select or enter a craft category.'), findsOneWidget);
      expect(find.text('Please enter the product region.'), findsOneWidget);
      expect(find.text('Please provide a more detailed product description.'), findsOneWidget);
      expect(find.text('Add at least one product tag.'), findsOneWidget);

      // Should NOT have navigated to Step 5
      expect(find.text('AI Pricing Step 5'), findsNothing);
    });

    testWidgets('rejects "Not specified" in material, technique, category, and region', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(productCreationProvider.notifier).setCatalogDetails(
        title: 'Handcrafted Vase',
        material: 'Not specified',
        technique: 'not specified',
        craftCategory: 'Not Specified',
        region: 'Not specified',
        description: 'Short desc',
        tags: ['Pottery'],
      );

      await tester.pumpWidget(buildCatalogScreenWithRouter(container));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Accept & Price'));
      await tester.tap(find.text('Accept & Price'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the material used to make this product.'), findsOneWidget);
      expect(find.text('Please enter the craft technique.'), findsOneWidget);
      expect(find.text('Please select or enter a craft category.'), findsOneWidget);
      expect(find.text('Please enter the product region.'), findsOneWidget);
      expect(find.text('Please provide a more detailed product description.'), findsOneWidget);
      expect(find.text('AI Pricing Step 5'), findsNothing);
    });

    testWidgets('navigates to Step 5 when all fields and tags are valid', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(productCreationProvider.notifier).setCatalogDetails(
        title: 'Handcrafted Terracotta Water Pot',
        material: 'Terracotta Clay',
        technique: 'Wheel Throwing and Pit Firing',
        craftCategory: 'Pottery',
        region: 'Bankura, West Bengal',
        description: 'Authentic handmade terracotta natural cooling water pot made with river clay.',
        tags: ['Eco-friendly', 'Terracotta'],
      );

      await tester.pumpWidget(buildCatalogScreenWithRouter(container));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Accept & Price'));
      await tester.tap(find.text('Accept & Price'));
      await tester.pumpAndSettle();

      // Successfully navigated to Step 5
      expect(find.text('AI Pricing Step 5'), findsOneWidget);
    });
  });

  group('Step 7 — ProductPublishedScreen Navigation Tests', () {
    Widget buildPublishedScreen(ProviderContainer container) {
      final router = GoRouter(
        initialLocation: '/product-published',
        routes: [
          GoRoute(
            path: '/product-published',
            builder: (context, state) => const ProductPublishedScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Artisan Home Screen')),
          ),
          GoRoute(
            path: '/products/add',
            builder: (context, state) => const Scaffold(body: Text('Capture Step 1 Screen')),
          ),
        ],
      );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
    }

    testWidgets('renders published confirmation and Go to Home Page button', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(productCreationProvider.notifier).setCatalogDetails(
        title: 'Brass Dhokra Lamp',
      );
      container.read(productCreationProvider.notifier).setPrice(1800);

      await tester.pumpWidget(buildPublishedScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('✓ Product Published!'), findsOneWidget);
      expect(find.text('Brass Dhokra Lamp'), findsOneWidget);
      expect(find.text('₹1800 • Stock: 12 Units'), findsOneWidget);
      expect(find.text('View Product Details'), findsOneWidget);
      expect(find.text('Add Another Product'), findsOneWidget);
      expect(find.text('Go to Home Page'), findsOneWidget);
      expect(find.text('Go to All Products'), findsNothing);
    });

    testWidgets('Go to Home Page navigates to Artisan Home and clears draft session', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Full creation session
      final notifier = container.read(productCreationProvider.notifier);
      notifier.addPhoto(File('main_craft.jpg'));
      notifier.setDescription('Hand-painted Madhubani folk art on handmade paper.');
      notifier.setCatalogDetails(
        title: 'Madhubani Tree of Life',
        material: 'Handmade Paper, Natural Pigments',
        technique: 'Fine Nib Freehand',
        craftCategory: 'Painting',
        region: 'Mithila, Bihar',
        tags: ['Heritage', 'Eco-friendly', 'Madhubani'],
      );
      notifier.setPrice(4500);

      await tester.pumpWidget(buildPublishedScreen(container));
      await tester.pumpAndSettle();

      expect(find.text('Madhubani Tree of Life'), findsOneWidget);

      // Tap 'Go to Home Page'
      await tester.tap(find.text('Go to Home Page'));
      await tester.pumpAndSettle();

      // Artisan Home reached
      expect(find.text('Artisan Home Screen'), findsOneWidget);

      // Session cleared
      final clearedSession = container.read(productCreationProvider);
      expect(clearedSession.photos, isEmpty);
      expect(clearedSession.title, isEmpty);
      expect(clearedSession.description, isEmpty);
      expect(clearedSession.tags, isEmpty);
    });

    testWidgets('Add Another Product navigates to Step 1 Capture and resets draft', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productCreationProvider.notifier);
      notifier.addPhoto(File('main_craft.jpg'));
      notifier.setCatalogDetails(
        title: 'Product A Title',
        tags: ['TagA'],
      );

      await tester.pumpWidget(buildPublishedScreen(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Another Product'));
      await tester.pumpAndSettle();

      expect(find.text('Capture Step 1 Screen'), findsOneWidget);

      // Session cleared for fresh product
      final clearedSession = container.read(productCreationProvider);
      expect(clearedSession.photos, isEmpty);
      expect(clearedSession.title, isEmpty);
      expect(clearedSession.tags, isEmpty);
    });
  });
}

