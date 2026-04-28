import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/presentation/views/auth/login_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';

class OnboardingLoadingPage extends StatelessWidget {
  const OnboardingLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.088;

    return Scaffold(
      backgroundColor: colors.gray10,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '거의 다 왔어요!',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.8,
                      color: colors.gray900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '로그인하면 AI가 맞춤 커리큘럼을\n바로 만들어 드릴게요.',
                    style: Typo.bodyRegular(context).copyWith(
                      color: colors.gray500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Assets.images.mainImage.image(
                    width: screenWidth * 0.6,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildBottomButton(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, ThemeColors colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.088;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 34,
      ),
      child: CustomButton(
        text: '로그인하고 시작하기',
        size: ButtonSize.large,
        theme: CustomButtonTheme.primary,
        width: double.infinity,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        },
      ),
    );
  }
}
