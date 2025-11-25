import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.088),
          child: Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  Text(
                    '끝공으로 합격한 합격자 수',
                    textAlign: TextAlign.center,
                    style: Typo.bodyRegular(context).copyWith(
                      color: colors.gray900,
                    ),
                  ),
                  Text(
                    '102,870,965',
                    textAlign: TextAlign.center,
                    style: Typo.displayStrong(context)
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: '카카오로 시작하기',
                      theme: CustomButtonTheme.grayscale,
                      size: ButtonSize.large,
                      backgroundColor: const Color(0xFFFEE500),
                      textColor: colors.gray900,
                      leftIcon: Assets.icons.kakaoLogo,
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: '구글로 시작하기',
                      theme: CustomButtonTheme.grayscale,
                      size: ButtonSize.large,
                      backgroundColor: colors.gray0,
                      textColor: colors.gray900,
                      leftIcon: Assets.icons.googleLogo,
                      useDefaultIconColor: true,
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Apple로 시작하기',
                      theme: CustomButtonTheme.grayscale,
                      size: ButtonSize.large,
                      backgroundColor: colors.gray900,
                      textColor: colors.gray0,
                      leftIcon: Assets.icons.appleLogo,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.045),
            ],
          ),
        ),
      ),
    );
  }
}
