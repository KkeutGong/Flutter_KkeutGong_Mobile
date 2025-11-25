import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/skeleton.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

Widget buildHomeSkeletonLoading(BuildContext context, ThemeColors colors, double screenWidth, double screenHeight) {
  final horizontalPadding = screenWidth * 0.188;
  final iconSize = screenWidth * 0.081;
  final arrowSize = screenWidth * 0.071;

  return SafeArea(
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.061,
            vertical: screenWidth * 0.031,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.013,
                  vertical: screenWidth * 0.010,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.gray300, width: 1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Assets.icons.memory.svg(
                        colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                      ),
                    ),
                    SizedBox(
                      width: arrowSize,
                      height: arrowSize,
                      child: Assets.icons.keyboardArrowDown.svg(
                        colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Assets.icons.notificationsUnread.svg(
                      colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.031),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.028,
                      vertical: screenWidth * 0.010,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.gray300, width: 1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Skeleton(
                          width: 20,
                          height: 20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        SizedBox(width: screenWidth * 0.010),
                        SizedBox(
                          width: screenWidth * 0.061,
                          height: screenWidth * 0.061,
                          child: Stack(
                            children: [
                              Assets.icons.flashOnFill.svg(
                                width: screenWidth * 0.061,
                                height: screenWidth * 0.061,
                                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                              ),
                              Padding(
                                padding: EdgeInsets.all(screenWidth * 0.0025),
                                child: Assets.icons.flashOnFill.svg(
                                  width: screenWidth * 0.061 * 0.875,
                                  height: screenWidth * 0.061 * 0.875,
                                  colorFilter: const ColorFilter.mode(Color(0xFFF5C905), BlendMode.srcIn),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.049),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colors.gray90,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: screenHeight * 0.019),
              Skeleton(
                width: screenWidth * 0.4,
                height: 24,
                borderRadius: BorderRadius.circular(8),
              ),
              SizedBox(height: 5),
              Skeleton(
                width: screenWidth * 0.15,
                height: 20,
                borderRadius: BorderRadius.circular(8),
              ),
              SizedBox(height: screenHeight * 0.038),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.122,
                  vertical: screenWidth * 0.061,
                ),
                decoration: BoxDecoration(
                  color: colors.gray0,
                  border: Border.all(color: colors.gray300, width: 1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.234,
                      height: screenWidth * 0.234,
                      child: Assets.icons.draw.svg(
                        colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.036),
                    Skeleton(
                      width: screenWidth * 0.25,
                      height: 24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.019),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index > 0 ? screenWidth * 0.015 : 0),
                    child: Container(
                      width: screenWidth * 0.023,
                      height: screenWidth * 0.023,
                      decoration: BoxDecoration(
                        color: index == 0 ? colors.primaryNormal : colors.gray60,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.063),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.081),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.046,
              screenWidth * 0.081,
              screenWidth * 0.046,
              screenWidth * 0.031,
            ),
            decoration: BoxDecoration(
              color: colors.gray0,
              border: Border.all(color: colors.gray70, width: 1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: [
                for (int i = 0; i < 2; i++) ...[
                  if (i > 0) SizedBox(height: screenWidth * 0.031),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Skeleton(
                        width: screenWidth * 0.35,
                        height: 20,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      Container(
                        width: screenWidth * 0.046,
                        height: screenWidth * 0.046,
                        decoration: BoxDecoration(
                          color: colors.gray40,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: screenWidth * 0.051),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primaryNormal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Skeleton(
                      width: screenWidth * 0.3,
                      height: 20,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
