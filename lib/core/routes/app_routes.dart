import 'package:get/get.dart';
import 'package:kkeutgong_mobile/pages/main.dart';

class AppRoutes {
  static const String main = '/';
  static const String login = '/login';

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
  ];
}
