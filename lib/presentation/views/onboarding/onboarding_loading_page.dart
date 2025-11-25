import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/presentation/views/auth/login_page.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

class OnboardingLoadingPage extends StatelessWidget {
  const OnboardingLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray10,
      body: SafeArea(
        child: Column(
          children: [
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
        text: '계속하기',
        size: ButtonSize.large,
        theme: CustomButtonTheme.grayscale,
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
