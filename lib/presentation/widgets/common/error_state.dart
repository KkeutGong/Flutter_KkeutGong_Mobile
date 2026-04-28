import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.gray300),
            const SizedBox(height: 12),
            Text(
              message ?? '오류가 발생했습니다.',
              style: Typo.bodyRegular(context, color: colors.gray600),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  '다시 시도',
                  style: Typo.bodyStrong(context, color: colors.primaryNormal),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
