// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '끝공';

  @override
  String get start => '시작하기';

  @override
  String get next => '다음';

  @override
  String get previous => '이전';

  @override
  String get correct => '정답';

  @override
  String get incorrect => '오답';

  @override
  String get continue_action => '계속하기';

  @override
  String get logout => '로그아웃';

  @override
  String get settings => '설정';

  @override
  String get loading => '불러오는 중…';

  @override
  String get retry => '다시 시도';
}
