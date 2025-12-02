import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/presentation/views/curriculum/curriculum_page.dart';
import 'package:kkeutgong_mobile/presentation/views/home/home_page.dart';
import 'package:kkeutgong_mobile/presentation/views/report/report_page.dart';
import 'package:kkeutgong_mobile/presentation/views/profile/profile_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/my_bottom_navigation_bar.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _homeKey = 0;
  int _curriculumKey = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomePage(key: ValueKey('home_$_homeKey'));
      case 1:
        return CurriculumPage(key: ValueKey('curriculum_$_curriculumKey'));
      case 2:
        return const ReportPage();
      case 3:
        return const ProfilePage();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeColors colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray20,
      extendBody: true,
      body: _buildPage(_currentIndex),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 0 && _currentIndex != 0) {
              _homeKey++;
            }
            if (index == 1 && _currentIndex != 1) {
              _curriculumKey++;
            }
            _currentIndex = index;
          });
        },
      ),
    );
  }
}