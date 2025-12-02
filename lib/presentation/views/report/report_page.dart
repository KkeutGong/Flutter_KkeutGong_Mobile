import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        title: Text('리포트', style: Typo.headingRegular(context, color: colors.gray900)),
        centerTitle: true,
      ),
      body: Center(
        child: Text('리포트 페이지 (placeholder)', style: Typo.bodyRegular(context, color: colors.gray600)),
      ),
    );
  }
}
