import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/presentation/views/home/home_page.dart';
import 'package:kkeutgong_mobile/presentation/views/curriculum/curriculum_page.dart';
import 'package:kkeutgong_mobile/presentation/views/report/report_page.dart';
import 'package:kkeutgong_mobile/presentation/views/profile/profile_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/my_bottom_navigation_bar.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;
    
    final List<Widget> pages = const [
      HomePage(),
      CurriculumPage(),
      ReportPage(),
      ProfilePage(),
    ];

    ThemeColors colors = ThemeColors.of(context); 

    return Scaffold(
      backgroundColor: colors.gray20,
      extendBody: true,
      body: Obx(() => pages[currentIndex.value]),
      bottomNavigationBar: Obx(() => MyBottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) {
          currentIndex.value = index;
        },
      )),
    );
  }
}
