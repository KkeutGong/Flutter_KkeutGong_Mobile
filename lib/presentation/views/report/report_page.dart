import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/report/report_repository.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/report/report_viewmodel.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/empty_state.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/error_state.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final ReportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReportViewModel();
    _viewModel.addListener(_onChanged);
    _viewModel.loadReport();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

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
      body: _buildBody(context, colors),
    );
  }

  Widget _buildBody(BuildContext context, ThemeColors colors) {
    if (_viewModel.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primaryNormal));
    }

    if (_viewModel.error != null) {
      return ErrorState(
        message: '리포트를 불러오지 못했습니다.',
        onRetry: _viewModel.loadReport,
      );
    }

    final data = _viewModel.data;
    if (data == null || data.subjects.isEmpty) {
      return const EmptyState(
        message: '아직 학습 기록이 없어요.\n커리큘럼을 시작하면 리포트가 생성됩니다.',
        icon: Icons.bar_chart_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      color: colors.primaryNormal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, colors, data),
            const SizedBox(height: 20),
            if (data.strongestSubject != null || data.weakestSubject != null) ...[
              _buildStrengthSection(context, colors, data),
              const SizedBox(height: 20),
            ],
            if (data.recentExamResult != null) ...[
              _buildExamResultCard(context, colors, data.recentExamResult!),
              const SizedBox(height: 20),
            ],
            _buildSubjectList(context, colors, data),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeColors colors, ReportData data) {
    final percentage = (data.overallProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.certificateName} · $percentage%',
            style: Typo.titleStrong(context, color: colors.gray900),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(colors, data.overallProgress),
          const SizedBox(height: 8),
          Text(
            '전체 진행률',
            style: Typo.labelRegular(context, color: colors.gray300),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeColors colors, double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: colors.primaryNormal,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthSection(BuildContext context, ThemeColors colors, ReportData data) {
    return Row(
      children: [
        if (data.strongestSubject != null)
          Expanded(
            child: _buildSubjectHighlightCard(
              context,
              colors,
              label: '강점 과목',
              subject: data.strongestSubject!,
              labelColor: colors.greenNormal,
            ),
          ),
        if (data.strongestSubject != null && data.weakestSubject != null)
          const SizedBox(width: 12),
        if (data.weakestSubject != null)
          Expanded(
            child: _buildSubjectHighlightCard(
              context,
              colors,
              label: '약점 과목',
              subject: data.weakestSubject!,
              labelColor: colors.primaryNormal,
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectHighlightCard(
    BuildContext context,
    ThemeColors colors, {
    required String label,
    required ReportSubject subject,
    required Color labelColor,
  }) {
    final conceptPct = (subject.conceptCompletionRate * 100).round();
    final practicePct = (subject.practiceCompletionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Typo.labelStrong(context, color: labelColor)),
          const SizedBox(height: 8),
          Text(
            subject.subjectName,
            style: Typo.bodyStrong(context, color: colors.gray900),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text('개념 $conceptPct%', style: Typo.footnoteRegular(context, color: colors.gray600)),
          const SizedBox(height: 2),
          Text('기출 $practicePct%', style: Typo.footnoteRegular(context, color: colors.gray600)),
        ],
      ),
    );
  }

  Widget _buildExamResultCard(BuildContext context, ThemeColors colors, ReportExamResult result) {
    final correctPct = (result.correctRate * 100).round();
    final minutes = result.elapsedSeconds ~/ 60;
    final seconds = result.elapsedSeconds % 60;
    final passColor = result.isPassed ? colors.greenNormal : colors.primaryNormal;
    final passLabel = result.isPassed ? '합격' : '불합격';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '최근 모의고사',
                  style: Typo.labelRegular(context, color: colors.gray300),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.isPassed ? colors.greenLight : colors.primaryLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(passLabel, style: Typo.labelStrong(context, color: passColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.examName, style: Typo.bodyStrong(context, color: colors.gray900)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(context, colors, '정답률', '$correctPct%'),
              const SizedBox(width: 12),
              _buildStatChip(context, colors, '맞은 문제', '${result.correctCount}/${result.totalQuestions}'),
              const SizedBox(width: 12),
              _buildStatChip(context, colors, '소요 시간', '${minutes}분 ${seconds}초'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, ThemeColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Typo.footnoteRegular(context, color: colors.gray300)),
        const SizedBox(height: 2),
        Text(value, style: Typo.bodyStrong(context, color: colors.gray900)),
      ],
    );
  }

  Widget _buildSubjectList(BuildContext context, ThemeColors colors, ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('과목별 진행률', style: Typo.headingStrong(context, color: colors.gray900)),
        const SizedBox(height: 12),
        ...data.subjects.map(
          (subject) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSubjectProgressCard(context, colors, subject),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectProgressCard(BuildContext context, ThemeColors colors, ReportSubject subject) {
    final conceptPct = (subject.conceptCompletionRate * 100).round();
    final practicePct = (subject.practiceCompletionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.gray0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gray70),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject.subjectName, style: Typo.bodyStrong(context, color: colors.gray900)),
          const SizedBox(height: 12),
          _buildModeProgress(context, colors, '개념 정리', subject.conceptCompletionRate, '$conceptPct%'),
          const SizedBox(height: 8),
          _buildModeProgress(context, colors, '기출 문제', subject.practiceCompletionRate, '$practicePct%'),
        ],
      ),
    );
  }

  Widget _buildModeProgress(
      BuildContext context, ThemeColors colors, String label, double progress, String pctLabel) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: Typo.footnoteRegular(context, color: colors.gray600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primaryNormal,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(pctLabel, style: Typo.footnoteRegular(context, color: colors.gray600), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
