import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repo = StudyProgressRepository();
  double _overall = 0.0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadOverall();
  }

  Future<void> _loadOverall() async {
    final v = await _repo.getOverallProgress();
    if (!mounted) return;
    setState(() => _overall = v);
  }

  Future<void> _resetPercents() async {
    setState(() => _loading = true);
    await _repo.resetAllProgress();
    HomeRepository().invalidateCache();
    final v = await _repo.getOverallProgress();
    if (!mounted) return;
    setState(() {
      _overall = v;
      _loading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 진행 상황이 초기화되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375).clamp(0.85, 1.4);

    final percentLabel = '${(_overall * 100).round()}%';

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        title: Text('프로필', style: Typo.headingRegular(context, color: colors.gray900)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                text: _loading ? '초기화 중…' : '모든 진행 상황 초기화',
                size: ButtonSize.large,
                theme: CustomButtonTheme.grayscale,
                onPressed: _loading ? null : _resetPercents,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
