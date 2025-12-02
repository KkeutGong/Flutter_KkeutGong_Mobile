import 'package:get/get.dart';
import 'package:kkeutgong_mobile/pages/main.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_welcome_page.dart';
import 'package:kkeutgong_mobile/presentation/views/study/concept_study_page.dart';
import 'package:kkeutgong_mobile/presentation/views/study/practice_study_page.dart';
import 'package:kkeutgong_mobile/presentation/views/study/mock_exam_page.dart';

class AppRoutes {
  static const String main = '/';
  static const String welcome = '/welcome';
  static const String conceptStudy = '/study/concept';
  static const String practiceStudy = '/study/practice';
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
      name: conceptStudy,
      page: () => ConceptStudyPage(subjectName: Get.arguments?['subjectName'] ?? ''),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: practiceStudy,
      page: () => PracticeStudyPage(subjectName: Get.arguments?['subjectName'] ?? ''),
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
