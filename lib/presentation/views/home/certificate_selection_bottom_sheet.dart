import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

class CertificateSelectionBottomSheet extends StatelessWidget {
  const CertificateSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    final leftPadding = screenWidth * 0.061;
    final topPadding = screenWidth * 0.165;
    final headerHorizontalPadding = screenWidth * 0.036;
    final headerVerticalPadding = screenWidth * 0.020;
    final memoryIconSize = screenWidth * 0.081;
    final arrowIconSize = screenWidth * 0.071;
    final containerWidth = screenWidth * 0.224;
    final optionIconSize1 = screenWidth * 0.076;
    final optionIconSize2 = screenWidth * 0.071;
    final iconGap = screenWidth * 0.025;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black26,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(left: leftPadding, top: topPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.gray20,
                  border: Border(
                    top: BorderSide(color: colors.gray300, width: 1),
                    left: BorderSide(color: colors.gray300, width: 1),
                    right: BorderSide(color: colors.gray300, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: headerHorizontalPadding,
                  vertical: headerVerticalPadding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: memoryIconSize,
                      height: memoryIconSize,
                      child: Assets.icons.memory.svg(
                        colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                      ),
                    ),
                    SizedBox(
                      width: arrowIconSize,
                      height: arrowIconSize,
                      child: Assets.icons.keyboardArrowUp.svg(
                        colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: containerWidth,
                decoration: BoxDecoration(
                  color: colors.gray20,
                  border: Border(
                    left: BorderSide(color: colors.gray300, width: 1),
                    right: BorderSide(color: colors.gray300, width: 1),
                    bottom: BorderSide(color: colors.gray300, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  headerHorizontalPadding,
                  screenWidth * 0.008,
                  headerHorizontalPadding,
                  screenWidth * 0.020,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: memoryIconSize,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: optionIconSize1,
                            height: optionIconSize1,
                            child: Assets.icons.desktopMac.svg(
                              colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                            ),
                          ),
                          SizedBox(height: iconGap),
                          SizedBox(
                            width: optionIconSize2,
                            height: optionIconSize2,
                            child: Assets.icons.menuBook.svg(
                              colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
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
        ),
      ),
    );
  }
}
