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
    final screenWidth = MediaQuery.of(context).size.width;
    
    final horizontalPadding = screenWidth > 600 ? 48.0 : 24.0;
    final itemSpacing = screenWidth > 600 ? 50.0 : 
                        screenWidth > 400 ? 40.0 : 35.0;
    final iconSize = screenWidth > 600 ? 28.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        color: colors.gray0,
        border: Border(top: BorderSide(color: colors.gray70, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Assets.icons.home,
                  selectedIcon: Assets.icons.homeFill,
                  label: '홈',
                  index: 0,
                  colors: colors,
                  iconSize: iconSize,
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: _buildNavItem(
                  icon: Assets.icons.route,
                  selectedIcon: Assets.icons.routeFill,
                  label: '커리큘럼',
                  index: 1,
                  colors: colors,
                  iconSize: iconSize,
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: _buildNavItem(
                  icon: Assets.icons.article,
                  selectedIcon: Assets.icons.articleFill,
                  label: '리포트',
                  index: 2,
                  colors: colors,
                  iconSize: iconSize,
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: _buildNavItem(
                  icon: Assets.icons.person,
                  selectedIcon: Assets.icons.personFill,
                  label: '프로필',
                  index: 3,
                  colors: colors,
                  iconSize: iconSize,
                ),
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
    required double iconSize,
  }) {
    final isSelected = widget.currentIndex == index;
    final currentIcon = isSelected ? selectedIcon : icon;
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalPadding = screenWidth > 600 ? 16.0 : 12.0;
    
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              currentIcon.svg(
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  isSelected ? colors.gray900 : colors.gray70,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: Typo.footnoteRegular(
                    context,
                    color: isSelected ? colors.gray900 : colors.gray70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}