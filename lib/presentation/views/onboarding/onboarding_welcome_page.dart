import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/views/auth/login_page.dart';
import 'package:kkeutgong_mobile/presentation/views/onboarding/onboarding_container_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_text_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final widthRatio = screenWidth / 393;
    final heightRatio = screenHeight / 852;

    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 95 * heightRatio),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 31 * widthRatio),
                  child: SizedBox(
                    height: 128 * heightRatio,
                    child: Text(
                      '포기하지 않는\n경험을 만듭니다.',
                      style: TextStyle(
                        fontFamily: 'SeoulAlrim',
                        fontSize: 48 * widthRatio,
                        fontWeight: FontWeight.w800,
                        height: 1.33,
                        letterSpacing: -1.44 * widthRatio,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: (263 - 95 - 128) * heightRatio),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 33 * widthRatio),
                  child: SizedBox(
                    width: 314 * widthRatio,
                    height: 232 * heightRatio,
                    child: Assets.images.mainImage.image(fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: (535 - 263 - 232) * heightRatio),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 57 * widthRatio),
                  child: SizedBox(
                    height: 56 * heightRatio,
                    child: Text(
                      'AI가 매일의 학습 루틴을 설계하고\n합격까지 이끌어 드립니다.',
                      style: TextStyle(
                        fontFamily: 'SeoulAlrim',
                        fontSize: 20 * widthRatio,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.4 * widthRatio,
                        color: const Color(0xFF575757),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 33 * widthRatio),
                  child: Semantics(
                    button: true,
                    identifier: 'onboarding-welcome-continue',
                    label: '계속하기',
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: '계속하기',
                        theme: CustomButtonTheme.primary,
                        size: ButtonSize.large,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingContainerPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * heightRatio),
                // M6: 로그인 하기는 의도적으로 LoginPage로 이동합니다.
                // 계속하기(신규 가입) → OnboardingContainerPage(자격증/시간 선택)
                // 로그인 하기(기존 계정) → LoginPage(소셜 로그인)
                CustomTextButton(
                  text: '로그인 하기',
                  theme: CustomTextButtonTheme.grayscale,
                  size: TextButtonSize.large,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16 * heightRatio),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
