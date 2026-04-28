import 'package:get/get.dart';
import 'package:kkeutgong_mobile/pages/main.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_certificate_select_page.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_exam_date_page.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_generating_page.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_hours_page.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_welcome_page.dart';
import 'package:kkeutgong_mobile/presentation/views/study/concept_study_page.dart';
import 'package:kkeutgong_mobile/presentation/views/study/mock_exam_page.dart';
import 'package:kkeutgong_mobile/presentation/views/study/practice_study_page.dart';

class AppRoutes {
  static const String main = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String onboardingExamDate = '/onboarding/exam-date';
  static const String onboardingHours = '/onboarding/hours';
  static const String onboardingGenerating = '/onboarding/generating';
  static const String conceptStudy = '/study/concept';
  static const String practiceStudy = '/study/practice';
  static const String review = '/study/review';
  static const String mockExam = '/study/mock-exam';

  static List<GetPage> routes = [
    GetPage(
      name: main,
      page: () => const MainPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: welcome,
      page: () => const OnboardingWelcomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingCertificateSelectPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: onboardingExamDate,
      page: () => const OnboardingExamDatePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: onboardingHours,
      page: () => const OnboardingHoursPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: onboardingGenerating,
      page: () => const OnboardingGeneratingPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: conceptStudy,
      page: () => ConceptStudyPage(
          subjectName: Get.arguments?['subjectName'] ?? ''),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: practiceStudy,
      page: () => PracticeStudyPage(
          subjectName: Get.arguments?['subjectName'] ?? ''),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: review,
      page: () => PracticeStudyPage(
          subjectName: Get.arguments?['subjectName'] ?? ''),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: mockExam,
      page: () => MockExamPage(
        examName: Get.arguments?['examName'] ?? '모의고사',
        timeLimitMinutes: Get.arguments?['timeLimitMinutes'] ?? 150,
      ),
      transition: Transition.rightToLeft,
    ),
  ];
}
