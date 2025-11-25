import 'package:get/get.dart';
import 'package:kkeutgong_mobile/pages/main.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_welcome_page.dart';

class AppRoutes {
  static const String main = '/';
  static const String welcome = '/welcome';

  static List<GetPage> routes = [
    GetPage(
      name: main,
      page: () => const MainPage(),
      transition: Transition.fadeIn,
    ),
    // TODO: Add login page route
    // GetPage(
    //   name: login,
    //   page: () => const LoginPage(),
    //   transition: Transition.fadeIn,
    // ),
    GetPage(
      name: welcome,
      page: () => const OnboardingWelcomePage(), // TODO: Replace with actual WelcomePage
      transition: Transition.fadeIn,
    ),
  ];
}
