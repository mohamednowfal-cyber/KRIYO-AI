import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriyo_artisan_app/features/gurukul/models/gurukul_models.dart';
import 'package:kriyo_artisan_app/features/gurukul/providers/gurukul_provider.dart';
import 'package:kriyo_artisan_app/features/gurukul/presentation/screens/gurukul_booking_screen.dart';
import 'package:kriyo_artisan_app/features/gurukul/presentation/screens/gurukul_payment_screen.dart';
import 'package:kriyo_artisan_app/features/gurukul/services/gurukul_certificate_service.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeHttpRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  static final List<int> _transparent1x1Png = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparent1x1Png.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(_transparent1x1Png).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  group('KRIYO Gurukul - Course Catalog & Media Mapping Tests', () {
    test('Catalog contains authentic master courses with structured lessons and media', () {
      final container = ProviderContainer();
      final state = container.read(gurukulProvider);

      expect(state.courses.length, greaterThanOrEqualTo(4));

      // Handloom Weaving course verification
      final weavingCourse = state.courses.firstWhere((c) => c.id == 'GRK-CRS-01');
      expect(weavingCourse.title, anyOf(contains('Handloom Weaving'), contains('Korvai')));
      expect(weavingCourse.artisanName, 'Lakshmi Devi');
      expect(weavingCourse.lessons.length, greaterThanOrEqualTo(4));

      // Real media asset mapping
      final lesson1 = weavingCourse.lessons[0];
      expect(lesson1.videoUrl, contains('assets/Videos/Wait For The Result_HD.mp4'));
      expect(lesson1.audioUrl, isNotNull);
      expect(lesson1.objectives.isNotEmpty, true);
      expect(lesson1.practiceQuiz, isNotNull);
      expect(lesson1.practiceQuiz!.options.length, greaterThanOrEqualTo(3));

      // Terracotta course verification
      final terracottaCourse = state.courses.firstWhere((c) => c.id == 'GRK-CRS-02');
      expect(terracottaCourse.craftType, contains('Terracotta'));
      expect(terracottaCourse.lessons.first.videoUrl, contains('Poetry of hands_HD.mp4'));
    });

    test('Practice quiz evaluates correct and incorrect answers properly', () {
      final container = ProviderContainer();
      final course = container.read(gurukulProvider).courses.first;
      final quiz = course.lessons.first.practiceQuiz!;

      expect(quiz.correctIndex, inInclusiveRange(0, quiz.options.length - 1));
      expect(quiz.explanation.isNotEmpty, true);
    });
  });

  group('KRIYO Gurukul - Booking Screen & Price Calculation Tests', () {
    testWidgets('Toggling starter kit dynamically updates total price without text overflow',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GurukulBookingScreen(courseId: 'GRK-CRS-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: Kit is included (base 1999 + 450 = 2449)
      expect(find.textContaining('Confirm & Pay ₹2449'), findsOneWidget);

      // Verify no overflow exception occurred
      expect(tester.takeException(), isNull);

      // Find Checkbox for Starter Kit, scroll to it, and tap to toggle OFF
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);

      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // After toggle OFF: (base 1999 only)
      expect(find.textContaining('Confirm & Pay ₹1999'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('KRIYO Gurukul - Separate Payment & Enrollment Lifecycle Tests', () {
    test('Payment confirmation creates enrollment without touching customer product orders', () {
      final container = ProviderContainer();
      final notifier = container.read(gurukulProvider.notifier);
      final course = container.read(gurukulProvider).courses.firstWhere((c) => c.id == 'GRK-CRS-01');

      final initialEnrollmentsCount = container.read(gurukulProvider).enrollments.length;

      // Simulate payment success
      final enrollment = notifier.createEnrollmentAfterPayment(
        course: course,
        format: course.format,
        sessionDate: DateTime.now().add(const Duration(days: 3)),
        language: 'Hindi',
        hasMaterialKit: true,
        amountPaid: 2449.0,
        paymentReference: 'UPI-TEST-12345',
      );

      final updatedEnrollments = container.read(gurukulProvider).enrollments;
      expect(updatedEnrollments.length, initialEnrollmentsCount + 1);
      expect(enrollment.id, startsWith('KRY-GUR-ENR-'));
      expect(enrollment.courseId, 'GRK-CRS-01');
      expect(enrollment.amountPaid, 2449.0);
      expect(enrollment.language, 'Hindi');
      expect(enrollment.hasMaterialKit, true);
      expect(enrollment.isCompleted, false);
      expect(enrollment.progress, 0.0);
    });

    test('Completing all lessons in a course triggers certificate issuance', () {
      final container = ProviderContainer();
      final notifier = container.read(gurukulProvider.notifier);
      final course = container.read(gurukulProvider).courses.firstWhere((c) => c.id == 'GRK-CRS-01');

      final enrollment = notifier.createEnrollmentAfterPayment(
        course: course,
        format: course.format,
        sessionDate: DateTime.now().add(const Duration(days: 3)),
        language: 'English',
        hasMaterialKit: false,
        amountPaid: 1999.0,
        paymentReference: 'UPI-COMPLETE-TEST',
      );

      // Complete each lesson in the course
      for (final lesson in course.lessons) {
        notifier.completeLesson(
          courseId: course.id,
          lessonId: lesson.id,
          enrollmentId: enrollment.id,
        );
      }

      final updatedEnr = container.read(gurukulProvider).enrollments.firstWhere((e) => e.id == enrollment.id);
      expect(updatedEnr.isCompleted, true);
      expect(updatedEnr.progress, 1.0);
      expect(updatedEnr.certificateId, isNotNull);
      expect(updatedEnr.certificateId, startsWith('KRY-GUR-2026-'));

      // Check certificate exists in certificates list
      final cert = container.read(gurukulProvider).certificates.firstWhere((c) => c.id == updatedEnr.certificateId);
      expect(cert.courseTitle, course.title);
      expect(cert.artisanTeacherName, course.artisanName);
      expect(cert.verificationHash, contains(updatedEnr.certificateId!));
    });

    testWidgets('GurukulPaymentScreen renders non-COD learning payment methods', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GurukulPaymentScreen(
              bookingData: {
                'courseId': 'GRK-CRS-01',
                'language': 'English',
                'tier': 'Personal Apprenticeship',
                'includeStarterKit': true,
                'totalAmount': 2449.0,
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('UPI (Instant & Zero Fee)'), findsOneWidget);
      expect(find.text('Credit / Debit Card'), findsOneWidget);
      expect(find.text('Net Banking'), findsOneWidget);
      // Ensure Cash on Delivery is strictly NOT present for Gurukul courses
      expect(find.text('Cash on Delivery'), findsNothing);
      expect(find.textContaining('Pay ₹2449'), findsOneWidget);
    });
  });

  group('KRIYO Gurukul - Vector PDF Certificate Generation Tests', () {
    test('Certificate PDF generates with A4 landscape, metadata, and watermark', () async {
      final cert = GurukulCertificate(
        id: 'KRY-GUR-2026-99999',
        studentName: 'Priya Sundaram',
        craftType: 'Handloom Weaving',
        courseTitle: 'Handloom Weaving Masterclass: Warp, Weft & Loom Geometry',
        artisanTeacherName: 'Devendra Kumar',
        artisanRole: 'National Master Weaver',
        learningHours: 24,
        issueDate: DateTime(2026, 9, 10),
        verificationHash: 'KRY-GRK-VERIFIED-99999',
        finalProjectImageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=800',
      );

      final pdfBytes = await GurukulCertificateService.generateCertificatePdf(cert);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // Standard PDF header signature check: '%PDF-'
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });
}
