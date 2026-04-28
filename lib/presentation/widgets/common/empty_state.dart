import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class EmptyState extends StatelessWidget {
  final String? message;
  final IconData? icon;

  const EmptyState({super.key, this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 48, color: colors.gray300),
            const SizedBox(height: 12),
            Text(
              message ?? '데이터가 없습니다.',
              style: Typo.bodyRegular(context, color: colors.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
