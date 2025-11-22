import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class MyBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.gray0,
        border: Border(top: BorderSide(color: colors.gray70, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(
                icon: Assets.icons.home,
                selectedIcon: Assets.icons.homeFill,
                label: '홈',
                index: 0,
                colors: colors,
              ),
              const SizedBox(width: 35),
              _buildNavItem(
                icon: Assets.icons.route,
                selectedIcon: Assets.icons.routeFill,
                label: '커리큘럼',
                index: 1,
                colors: colors,
              ),
              const SizedBox(width: 35),
              _buildNavItem(
                icon: Assets.icons.article,
                selectedIcon: Assets.icons.articleFill,
                label: '리포트',
                index: 2,
                colors: colors,
              ),
              const SizedBox(width: 35),
              _buildNavItem(
                icon: Assets.icons.person,
                selectedIcon: Assets.icons.personFill,
                label: '프로필',
                index: 3,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required dynamic icon,
    required dynamic selectedIcon,
    required String label,
    required int index,
    required ThemeColors colors,
  }) {
    final isSelected = widget.currentIndex == index;
    final currentIcon = isSelected ? selectedIcon : icon;
    
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        width: 60,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              currentIcon.svg(
                width: 24.0,
                height: 24.0,
                colorFilter: ColorFilter.mode(
                  isSelected ? colors.gray900 : colors.gray70,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Typo.footnoteRegular(
                  context,
                  color: isSelected ? colors.gray900 : colors.gray70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
