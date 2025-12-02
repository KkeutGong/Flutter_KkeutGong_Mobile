import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/study_card.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/study/concept_study_viewmodel.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class ConceptStudyPage extends StatefulWidget {
  final String subjectName;

  const ConceptStudyPage({super.key, required this.subjectName});

  @override
  State<ConceptStudyPage> createState() => _ConceptStudyPageState();
}

class _ConceptStudyPageState extends State<ConceptStudyPage> {
  late final ConceptStudyViewModel _viewModel;
  late final PageController _pageController;
  bool _isRoundTransition = false;
  bool _isSwipeInProgress = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ConceptStudyViewModel(subjectName: widget.subjectName);
    _pageController = PageController();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  void _onMarkAsKnown() {
    final wasLast = !_viewModel.hasNext;
    _viewModel.markAsKnown();
    if (wasLast && !_viewModel.isCompleted) {
      _viewModel.goToNext();
    }
  }

  void _onPageChanged(int index) {
    _viewModel.setCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    if (_viewModel.isLoading) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_viewModel.error != null) {
      return Scaffold(
        backgroundColor: colors.gray20,
        body: Center(child: Text('Error: ${_viewModel.error}')),
      );
    }

    if (_viewModel.isCompleted) {
      return _buildCompletedScreen(context, colors);
    }

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _buildAppBar(context, colors),
      body: WillPopScope(
        onWillPop: () async {
          await _viewModel.saveProgress();
          HomeRepository().invalidateCache();
          return true;
        },
        child: AnimatedOpacity(
          opacity: _isRoundTransition ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onHorizontalDragStart:
                _viewModel.currentIndex == _viewModel.totalCards - 1
                ? (details) {
                    _isSwipeInProgress = true;
                  }
                : null,
            onHorizontalDragEnd:
                _viewModel.currentIndex == _viewModel.totalCards - 1
                ? (details) {
                    if (_isSwipeInProgress) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -200 && !_isRoundTransition) {
                        _startRoundTransition();
                      }
                    }
                    _isSwipeInProgress = false;
                  }
                : null,
            onHorizontalDragUpdate:
                _viewModel.currentIndex == _viewModel.totalCards - 1
                ? (details) {}
                : null,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _viewModel.totalCards,
              onPageChanged: _onPageChanged,
              physics: _viewModel.currentIndex == _viewModel.totalCards - 1
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemBuilder: (context, index) {
                final card = _viewModel.cards[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: _FlashCard(
                    card: card,
                    onKnown: _onMarkAsKnown,
                    onUnmarkKnown: () {
                      _viewModel.unmarkAsKnown();
                    },
                    onToggleFavorite: _viewModel.toggleFavorite,
                    isLast: index == _viewModel.totalCards - 1,
                    isKnown: _viewModel.isKnown(card.id),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _startRoundTransition() {
    setState(() => _isRoundTransition = true);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _viewModel.forceNextRound();
      if (!_viewModel.isCompleted) {
        _pageController.jumpToPage(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _isRoundTransition = false);
      });
    });
  }

  Widget _buildCompletedScreen(BuildContext context, ThemeColors colors) {
    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.gray0,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.gray70),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.greenLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Assets.icons.check.svg(
                          width: 48,
                          height: 48,
                          colorFilter: ColorFilter.mode(
                            colors.greenNormal,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '학습 완료!',
                      style: Typo.titleStrong(context, color: colors.gray900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_viewModel.totalAllCards}개의 카드를 모두 학습했습니다',
                      style: Typo.bodyRegular(context, color: colors.gray600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '총 ${_viewModel.round}라운드 진행',
                      style: Typo.labelRegular(
                        context,
                        color: colors.primaryNormal,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colors.primaryNormal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '완료',
                      style: Typo.bodyStrong(context, color: colors.gray0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context, ThemeColors colors) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: colors.gray0,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () async {
              await _viewModel.saveProgress();
              HomeRepository().invalidateCache();
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Assets.icons.arrowBackIos.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _viewModel.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primaryNormal,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                _viewModel.progressText,
                style: Typo.bodyRegular(context, color: colors.gray900),
              ),
              const SizedBox(width: 15),
            ],
          ),
          titleSpacing: 0,
        ),
      ),
    );
  }
}

class _FlashCard extends StatefulWidget {
  final StudyCard card;
  final VoidCallback onKnown;
  final VoidCallback onUnmarkKnown;
  final VoidCallback onToggleFavorite;
  final bool isLast;
  final bool isKnown;

  const _FlashCard({
    required this.card,
    required this.onKnown,
    required this.onUnmarkKnown,
    required this.onToggleFavorite,
    required this.isLast,
    required this.isKnown,
  });

  @override
  State<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<_FlashCard> {
  double _dragOffset = 0;
  bool _isDragging = false;

  static const double _closedCoverRatio = 0.42;
  static const double _openCoverRatio = 0.064;

  double _getCoverHeight(double cardHeight) {
    final closedHeight = cardHeight * _closedCoverRatio;
    final openHeight = cardHeight * _openCoverRatio;
    final maxDrag = closedHeight - openHeight;
    final currentHeight = closedHeight - _dragOffset.clamp(0, maxDrag);
    return currentHeight;
  }

  bool _isPartiallyRevealed(double cardHeight) {
    final closedHeight = cardHeight * _closedCoverRatio;
    final openHeight = cardHeight * _openCoverRatio;
    final maxDrag = closedHeight - openHeight;
    if (widget.isKnown) return true;
    return _dragOffset > maxDrag * 0.3;
  }

  bool _isFullyRevealed(double cardHeight) {
    final closedHeight = cardHeight * _closedCoverRatio;
    final openHeight = cardHeight * _openCoverRatio;
    final maxDrag = closedHeight - openHeight;
    if (widget.isKnown) return true;
    return _dragOffset > maxDrag * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final closedHeight = cardHeight * _closedCoverRatio;
        final openHeight = cardHeight * _openCoverRatio;
        final maxDrag = closedHeight - openHeight;

        if (widget.isKnown && _dragOffset == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _dragOffset = maxDrag;
            });
          });
        }

        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: colors.gray0,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.gray70),
          ),
          child: Stack(
            children: [
              _buildCardContent(context, colors, cardHeight),
              _buildCover(context, colors, cardHeight, maxDrag),
              if (_isFullyRevealed(cardHeight) || widget.isKnown)
                _buildKnownBadge(context, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    ThemeColors colors,
    double cardHeight,
  ) {
    final isFullyRevealed = _isFullyRevealed(cardHeight);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onToggleFavorite,
            child: widget.card.isFavorite
                ? Assets.icons.starFill.svg(
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colors.yellow,
                      BlendMode.srcIn,
                    ),
                  )
                : Assets.icons.star.svg(
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colors.gray70,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.card.question,
                  style: Typo.titleRegular(context, color: colors.gray900),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (isFullyRevealed || widget.isKnown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.isKnown ? '이미 학습된 카드입니다' : '',
                style: Typo.footnoteRegular(context, color: colors.gray70),
              ),
            ),
          SizedBox(
            height: cardHeight * 0.42,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 1, color: colors.gray70),
                ),
                Center(
                  child: Text(
                    widget.card.answer,
                    style: Typo.headingStrong(context, color: colors.gray900),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(
    BuildContext context,
    ThemeColors colors,
    double cardHeight,
    double maxDrag,
  ) {
    final coverHeight = _getCoverHeight(cardHeight);
    final isPartiallyRevealed = _isPartiallyRevealed(cardHeight);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, maxDrag);
          });
        },
        onVerticalDragEnd: (_) {
          setState(() {
            _isDragging = false;
            if (widget.isKnown) {
              if (_dragOffset < maxDrag * 0.7) {
                _dragOffset = 0;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onUnmarkKnown();
                });
              } else {
                _dragOffset = maxDrag;
              }
            } else {
              if (_dragOffset > maxDrag * 0.7) {
                _dragOffset = maxDrag;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onKnown();
                });
              } else {
                _dragOffset = 0;
              }
            }
          });
        },
        child: AnimatedContainer(
          duration: _isDragging
              ? Duration.zero
              : const Duration(milliseconds: 200),
          height: coverHeight,
          decoration: BoxDecoration(
            color: colors.primaryNormal,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: _buildCoverContent(context, colors, isPartiallyRevealed),
        ),
      ),
    );
  }

  Widget _buildCoverContent(
    BuildContext context,
    ThemeColors colors,
    bool isPartiallyRevealed,
  ) {
    if (isPartiallyRevealed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '아는 용어가 아니면 다시 덮어요',
            style: Typo.bodyStrong(context, color: colors.gray0),
          ),
          const SizedBox(width: 10),
          Transform.rotate(
            angle: -3.14159 / 2,
            child: Assets.icons.fastForward.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(colors.gray0, BlendMode.srcIn),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Transform.rotate(
          angle: 3.14159 / 2,
          child: Assets.icons.fastForward.svg(
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(colors.gray0, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '의미를 가리고 기억해 보세요.\n생각이 안나면 커버를 조금 내려\n확인하고 다음 카드로 넘기세요!',
          style: Typo.bodyStrong(context, color: colors.gray0),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildKnownBadge(BuildContext context, ThemeColors colors) {
    return Positioned(
      top: 0,
      right: 0,
      child: GestureDetector(
        onTap: widget.isKnown ? widget.onUnmarkKnown : widget.onKnown,
        child: Container(
          width: 93,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryNormal,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.icons.check.svg(
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(colors.gray0, BlendMode.srcIn),
              ),
              Text(
                '아는카드',
                style: Typo.bodyStrong(context, color: colors.gray0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
