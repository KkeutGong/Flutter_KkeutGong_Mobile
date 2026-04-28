import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  Future<void> _openStore() async {
    final url = Platform.isIOS
        ? (dotenv.maybeGet('APP_STORE_URL') ??
            'https://apps.apple.com/app/idXXXXXXXXX')
        : (dotenv.maybeGet('PLAY_STORE_URL') ??
            'https://play.google.com/store/apps/details?id=com.kkeutgong.app');
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
              Icon(Icons.system_update_alt_rounded,
                  size: 72, color: colors.primaryNormal),
              const SizedBox(height: 24),
              Text(
                '업데이트 필요',
                style: Typo.titleStrong(context, color: colors.gray900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '더 나은 서비스 제공을 위해\n앱을 최신 버전으로 업데이트해 주세요.',
                style: Typo.bodyRegular(context, color: colors.gray600),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryNormal,
                    foregroundColor: colors.gray0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '업데이트 하기',
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
