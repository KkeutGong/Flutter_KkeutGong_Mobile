import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/presentation/views/curriculum/curriculum_page.dart';
import 'package:kkeutgong_mobile/presentation/views/home/home_page.dart';
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
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    
    pages = const [
      HomePage(),
      CurriculumPage(),
      SizedBox(),
      SizedBox(),
    ];
  }

  @override
  Widget build(BuildContext context) {   
    ThemeColors colors = ThemeColors.of(context); 

    return Scaffold(
      backgroundColor: colors.gray20,
      extendBody: true,
      body: pages[_currentIndex],
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}