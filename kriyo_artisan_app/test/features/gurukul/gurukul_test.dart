import 'package:flutter_test/flutter_test.dart';
import 'package:kriyo_artisan_app/features/gurukul/models/gurukul_models.dart';
import 'package:kriyo_artisan_app/features/gurukul/providers/gurukul_provider.dart';

void main() {
  group('Gurukul Tutor Core Models & 7 Stages', () {
    test('GurukulJourneyStage has all 7 progressive stages in exact order', () {
      expect(GurukulJourneyStage.values.length, equals(7));
      expect(GurukulJourneyStage.understandingCraft.stageNumber, equals(1));
      expect(GurukulJourneyStage.materialsAndTools.stageNumber, equals(2));
      expect(GurukulJourneyStage.basicTechnique.stageNumber, equals(3));
      expect(GurukulJourneyStage.traditionalPattern.stageNumber, equals(4));
      expect(GurukulJourneyStage.createYourOwn.stageNumber, equals(5));
      expect(GurukulJourneyStage.artisanReview.stageNumber, equals(6));
      expect(GurukulJourneyStage.completion.stageNumber, equals(7));
    });

    test('CraftLearningCourse contains valid heritage context and lessons', () {
      final notifier = GurukulNotifier();
      final course = notifier.getCourseById('GRK-CRS-01');
      expect(course, isNotNull);
      expect(course!.id, equals('GRK-CRS-01'));
      expect(course.craftType, equals('Handloom Weaving'));
      expect(course.artisanName, equals('Lakshmi Devi'));
      expect(course.heritageContext, isNotEmpty);
      expect(course.lessons, isNotEmpty);
      expect(course.materialsRequired, isNotEmpty);
    });
  });

  group('Gurukul StateNotifier & Learning Lifecycle', () {
    late GurukulNotifier notifier;

    setUp(() {
      notifier = GurukulNotifier();
    });

    test('Initial state contains master courses and verified teachers', () {
      final state = notifier.state;
      expect(state.courses.length, greaterThanOrEqualTo(3));
      expect(state.teachers.length, greaterThanOrEqualTo(3));
      expect(state.enrollments, isNotEmpty);
      expect(state.certificates, isNotEmpty);
    });


    test('Teacher matching filters by craft tradition and language', () {
      final weavingTeachers = notifier.matchTeachers(craft: 'Weaving');
      expect(weavingTeachers.any((t) => t.name == 'Lakshmi Devi'), isTrue);

      final tamilTeachers = notifier.matchTeachers(language: 'Tamil');
      expect(tamilTeachers.isNotEmpty, isTrue);
    });

    test('enrollInCourse creates a new enrollment starting at Stage 2', () {
      final initialCount = notifier.state.enrollments.length;
      final course = notifier.state.courses.first;

      notifier.enrollInCourse(
        course: course,
        format: GurukulLearningFormat.onlineOneOnOne,
        sessionDate: DateTime.now().add(const Duration(days: 3)),
      );

      final state = notifier.state;
      expect(state.enrollments.length, equals(initialCount + 1));
      final newEnrollment = state.enrollments.first;
      expect(newEnrollment.courseId, equals(course.id));
      expect(newEnrollment.currentStageIndex, equals(1)); // Stage 2
      expect(newEnrollment.progress, greaterThan(0.1));
    });

    test('submitAssignment updates enrollment to Stage 6 (Artisan Review)', () {
      final enrollment = notifier.state.enrollments.first;

      notifier.submitAssignment(
        enrollmentId: enrollment.id,
        photoUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
        studentNote: 'Tension calibrated on warp thread rows 10-25',
      );

      final updated = notifier.state.enrollments.firstWhere((e) => e.id == enrollment.id);
      expect(updated.currentStageIndex, equals(5)); // Stage 6: Artisan Review
      expect(updated.submission, isNotNull);
      expect(updated.feedback, isNotNull);
      expect(updated.feedback!.isApproved, isTrue);
    });

    test('completeCourse generates official verified certificate and advances to Stage 7', () {
      final enrollment = notifier.state.enrollments.first;
      final initialCertCount = notifier.state.certificates.length;

      notifier.completeCourse(enrollment.id);

      final updated = notifier.state.enrollments.firstWhere((e) => e.id == enrollment.id);
      expect(updated.isCompleted, isTrue);
      expect(updated.progress, equals(1.0));
      expect(updated.currentStageIndex, equals(6)); // Stage 7
      expect(updated.certificateId, isNotNull);

      expect(notifier.state.certificates.length, equals(initialCertCount + 1));
      final newCert = notifier.state.certificates.first;
      expect(newCert.verificationHash, contains('KRY-GRK-VERIFIED'));
    });
  });
}
