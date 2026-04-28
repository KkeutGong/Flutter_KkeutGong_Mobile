import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kkeutgong_mobile/core/notifications/notification_service.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/data/repositories/auth/auth_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepo = AuthRepository();
  final _progressRepo = StudyProgressRepository();
  final _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  ThemeMode _themeMode = ThemeMode.system;
  String _appVersion = '';
  bool _loading = false;

  static const _prefNotifications = 'notifications_enabled';
  static const _prefThemeMode = 'theme_mode';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadVersion();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_prefNotifications) ?? false;
      final saved = prefs.getString(_prefThemeMode) ?? 'system';
      _themeMode = _themeModeFromString(saved);
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '라이트';
      case ThemeMode.dark:
        return '다크';
      case ThemeMode.system:
        return '시스템';
    }
  }

  Future<void> _setNotifications(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한이 거부되었습니다. 설정에서 허용해 주세요.')),
          );
        }
        return;
      }
      await _notificationService.scheduleDailyReminder();
    } else {
      await _notificationService.cancelAll();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifications, value);
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_prefThemeMode, modeStr);
    setState(() => _themeMode = mode);
    // Apply theme change to running app
    Get.changeThemeMode(mode);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await _authRepo.logout();
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.welcome);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말 탈퇴하시겠습니까?\n모든 학습 기록이 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await _authRepo.deleteAccount();
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.welcome);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('학습 기록 초기화'),
        content: const Text('모든 학습 기록을 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await _progressRepo.resetAllProgress();
      HomeRepository().invalidateCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학습 기록이 초기화되었습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        title: Text('설정', style: Typo.headingRegular(context, color: colors.gray900)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader(context, colors, '앱 설정'),
                _switchTile(
                  context,
                  colors,
                  icon: Icons.notifications_outlined,
                  title: '알림 설정',
                  identifier: 'settings-notifications-toggle',
                  value: _notificationsEnabled,
                  onChanged: _setNotifications,
                ),
                _themeTile(context, colors),
                _sectionHeader(context, colors, '학습'),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.workspace_premium_outlined,
                  title: '내 자격증 관리',
                  identifier: 'settings-manage-certificates',
                  onTap: () => Get.toNamed(AppRoutes.addCertificate),
                ),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.refresh,
                  title: '학습 기록 초기화',
                  identifier: 'settings-reset-progress',
                  onTap: _resetProgress,
                ),
                _sectionHeader(context, colors, '지원'),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.mail_outline,
                  title: '문의하기',
                  identifier: 'settings-contact',
                  onTap: () => _openUrl('mailto:contact@kkeutgong.com'),
                ),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  identifier: 'settings-privacy',
                  onTap: () => _openUrl('https://kkeutgong.com/privacy-ko'),
                ),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  identifier: 'settings-terms',
                  onTap: () => _openUrl('https://kkeutgong.com/terms-ko'),
                ),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.info_outline,
                  title: '오픈소스 라이선스',
                  identifier: 'settings-licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: '끝공',
                    applicationVersion: _appVersion,
                  ),
                ),
                _infoTile(context, colors, title: '앱 버전', value: _appVersion),
                _sectionHeader(context, colors, '계정'),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.logout,
                  title: '로그아웃',
                  identifier: 'settings-logout',
                  onTap: _logout,
                ),
                _actionTile(
                  context,
                  colors,
                  icon: Icons.person_remove_outlined,
                  title: '회원 탈퇴',
                  identifier: 'settings-delete-account',
                  titleColor: Colors.red,
                  onTap: _deleteAccount,
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, ThemeColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: Typo.labelStrong(context, color: colors.gray600),
      ),
    );
  }

  Widget _switchTile(
    BuildContext context,
    ThemeColors colors, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? identifier,
  }) {
    return Semantics(
      identifier: identifier,
      child: MergeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            secondary: Icon(icon, color: colors.gray900),
            title: Text(title, style: Typo.bodyRegular(context, color: colors.gray900)),
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primaryNormal,
          ),
        ),
      ),
    );
  }

  Widget _themeTile(BuildContext context, ThemeColors colors) {
    return Semantics(
      identifier: 'settings-darkmode',
      child: MergeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: colors.gray900),
            title: Text('다크 모드', style: Typo.bodyRegular(context, color: colors.gray900)),
            trailing: DropdownButton<ThemeMode>(
              value: _themeMode,
              underline: const SizedBox.shrink(),
              items: ThemeMode.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        _themeModeLabel(m),
                        style: Typo.bodyRegular(context, color: colors.gray900),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (m) {
                if (m != null) _setThemeMode(m);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    ThemeColors colors, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    String? identifier,
  }) {
    return Semantics(
      identifier: identifier,
      child: MergeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(icon, color: titleColor ?? colors.gray900),
            title: Text(
              title,
              style: Typo.bodyRegular(context, color: titleColor ?? colors.gray900),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.gray300),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    ThemeColors colors, {
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.tag, color: colors.gray900),
        title: Text(title, style: Typo.bodyRegular(context, color: colors.gray900)),
        trailing: Text(value, style: Typo.bodyRegular(context, color: colors.gray600)),
      ),
    );
  }
}
