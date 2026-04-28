import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class MaintenancePage extends StatelessWidget {
  final VoidCallback onRetry;
  const MaintenancePage({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.build_circle_outlined,
                  size: 72, color: colors.primaryNormal),
              const SizedBox(height: 24),
              Text(
                '서비스 점검 중',
                style: Typo.titleStrong(context, color: colors.gray900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '서비스 점검 중입니다.\n잠시 후 다시 시도해 주세요.',
                style: Typo.bodyRegular(context, color: colors.gray600),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryNormal,
                    foregroundColor: colors.gray0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '다시 시도',
                    style: Typo.bodyStrong(context, color: colors.gray0),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
