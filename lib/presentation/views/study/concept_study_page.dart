import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/domain/models/study/study_card.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/study/concept_study_viewmodel.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ResponsiveHelper {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final bool isSmallScreen;
  late final bool isMediumScreen;
  late final double scaleFactor;

  _ResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isSmallScreen = screenWidth < 360;
    isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    scaleFactor = (screenWidth / 375).clamp(0.85, 1.2);
  }

  double get horizontalPadding => isSmallScreen ? 14 : (isMediumScreen ? 17 : 20);
  double get iconSize => (24 * scaleFactor).clamp(20.0, 28.0);
  double get largeIconSize => (36 * scaleFactor).clamp(30.0, 42.0);
  double get checkIconSize => (48 * scaleFactor).clamp(40.0, 56.0);
  double get badgeWidth => (93 * scaleFactor).clamp(78.0, 108.0);
  double get badgeHeight => (72 * scaleFactor).clamp(60.0, 84.0);
  double get completedIconContainerSize => (80 * scaleFactor).clamp(68.0, 96.0);
}

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
  bool _showSwipeHint = false;

  static const _prefSwipeHintSeen = 'concept_swipe_hint_seen';

  @override
  void initState() {
    super.initState();
    _viewModel = ConceptStudyViewModel(subjectName: widget.subjectName);
    _pageController = PageController();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadCards();
    _checkSwipeHint();
  }

  Future<void> _checkSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_prefSwipeHintSeen) ?? false;
    if (!seen && mounted) {
      setState(() => _showSwipeHint = true);
      await prefs.setBool(_prefSwipeHintSeen, true);
    }
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
    final responsive = _ResponsiveHelper(context);

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
      return _buildCompletedScreen(context, colors, responsive);
    }

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: _buildAppBar(context, colors, responsive),
      body: Stack(
        children: [
          PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            await _viewModel.saveProgress();
            HomeRepository().invalidateCache();
          }
        },
        child: AnimatedOpacity(
          opacity: _isRoundTransition ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            identifier: 'concept-card',
            label: '개념 카드',
            button: false,
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
                  padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 12 * responsive.scaleFactor, responsive.horizontalPadding, responsive.horizontalPadding),
                  child: _FlashCard(
                    card: card,
                    onKnown: _onMarkAsKnown,
                    onUnmarkKnown: () {
                      _viewModel.unmarkAsKnown();
                    },
                    onToggleFavorite: _viewModel.toggleFavorite,
                    isLast: index == _viewModel.totalCards - 1,
                    isKnown: _viewModel.isKnown(card.id),
                    responsive: responsive,
                  ),
                );
              },
            ),
          ),
          ),
        ),
      ),
          // First-visit swipe interaction hint (shows once via SharedPreferences)
          if (_showSwipeHint)
            Positioned(
              left: 0,
              right: 0,
              bottom: responsive.horizontalPadding,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '↑ 위로 스와이프: 안다   ↓ 아래로: 모름',
                      style: Typo.footnoteRegular(context, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
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

  Widget _buildCompletedScreen(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    return Scaffold(
      backgroundColor: colors.gray20,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32 * responsive.scaleFactor),
                decoration: BoxDecoration(
                  color: colors.gray0,
                  borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                  border: Border.all(color: colors.gray70),
                ),
                child: Column(
                  children: [
                    Container(
                      width: responsive.completedIconContainerSize,
                      height: responsive.completedIconContainerSize,
                      decoration: BoxDecoration(
                        color: colors.greenLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Assets.icons.check.svg(
                          width: responsive.checkIconSize,
                          height: responsive.checkIconSize,
                          colorFilter: ColorFilter.mode(
                            colors.greenNormal,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24 * responsive.scaleFactor),
                    Text(
                      '학습 완료!',
                      style: Typo.titleStrong(context, color: colors.gray900),
                    ),
                    SizedBox(height: 12 * responsive.scaleFactor),
                    Text(
                      '${_viewModel.totalAllCards}개의 카드를 모두 학습했습니다',
                      style: Typo.bodyRegular(context, color: colors.gray600),
                    ),
                    SizedBox(height: 8 * responsive.scaleFactor),
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
                child: Semantics(
                  identifier: 'concept-close',
                  label: '닫기',
                  button: true,
                  child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16 * responsive.scaleFactor),
                    decoration: BoxDecoration(
                      color: colors.primaryNormal,
                      borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '완료',
                      style: Typo.bodyStrong(context, color: colors.gray0),
                    ),
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

  PreferredSize _buildAppBar(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: colors.gray0,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: colors.gray0,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Semantics(
            identifier: 'concept-back',
            label: '뒤로 가기',
            button: true,
            child: GestureDetector(
            onTap: () async {
              await _viewModel.saveProgress();
              HomeRepository().invalidateCache();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.all(15 * responsive.scaleFactor),
              child: Assets.icons.arrowBackIos.svg(
                width: responsive.iconSize,
                height: responsive.iconSize,
                colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
              ),
            ),
          ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Container(
                  height: 12 * responsive.scaleFactor,
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
              SizedBox(width: 15 * responsive.scaleFactor),
              Text(
                _viewModel.progressText,
                style: Typo.bodyRegular(context, color: colors.gray900),
              ),
              SizedBox(width: 15 * responsive.scaleFactor),
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
  final _ResponsiveHelper responsive;

  const _FlashCard({
    required this.card,
    required this.onKnown,
    required this.onUnmarkKnown,
    required this.onToggleFavorite,
    required this.isLast,
    required this.isKnown,
    required this.responsive,
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
    final responsive = widget.responsive;

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
            borderRadius: BorderRadius.circular(12 * responsive.scaleFactor),
            border: Border.all(color: colors.gray70),
          ),
          child: Stack(
            children: [
              _buildCardContent(context, colors, cardHeight, responsive),
              _buildCover(context, colors, cardHeight, maxDrag, responsive),
              if (_isFullyRevealed(cardHeight) || widget.isKnown)
                _buildKnownBadge(context, colors, responsive),
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
    _ResponsiveHelper responsive,
  ) {
    final isFullyRevealed = _isFullyRevealed(cardHeight);

    return Padding(
      padding: EdgeInsets.only(top: 20 * responsive.scaleFactor),
      child: Column(
        children: [
          Semantics(
            identifier: 'concept-favorite-toggle',
            label: '즐겨찾기 토글',
            button: true,
            child: GestureDetector(
            onTap: widget.onToggleFavorite,
            child: widget.card.isFavorite
                ? Assets.icons.starFill.svg(
                    width: responsive.iconSize,
                    height: responsive.iconSize,
                    colorFilter: ColorFilter.mode(
                      colors.yellow,
                      BlendMode.srcIn,
                    ),
                  )
                : Assets.icons.star.svg(
                    width: responsive.iconSize,
                    height: responsive.iconSize,
                    colorFilter: ColorFilter.mode(
                      colors.gray70,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32 * responsive.scaleFactor),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.card.sourceLabel != null &&
                        widget.card.sourceLabel!.isNotEmpty) ...[
                      _buildSourceBadge(context, colors, widget.card.sourceLabel!),
                      SizedBox(height: 12 * responsive.scaleFactor),
                    ],
                    Text(
                      widget.card.question,
                      style: Typo.titleRegular(context, color: colors.gray900),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isFullyRevealed || widget.isKnown)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * responsive.scaleFactor),
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
    _ResponsiveHelper responsive,
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
          child: _buildCoverContent(context, colors, isPartiallyRevealed, responsive),
        ),
      ),
    );
  }

  Widget _buildCoverContent(
    BuildContext context,
    ThemeColors colors,
    bool isPartiallyRevealed,
    _ResponsiveHelper responsive,
  ) {
    if (isPartiallyRevealed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '아는 용어가 아니면 다시 덮어요',
            style: Typo.bodyStrong(context, color: colors.gray0),
          ),
          SizedBox(width: 10 * responsive.scaleFactor),
          Transform.rotate(
            angle: -3.14159 / 2,
            child: Assets.icons.fastForward.svg(
              width: responsive.iconSize,
              height: responsive.iconSize,
              colorFilter: ColorFilter.mode(colors.gray0, BlendMode.srcIn),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 16 * responsive.scaleFactor),
        Transform.rotate(
          angle: 3.14159 / 2,
          child: Assets.icons.fastForward.svg(
            width: responsive.largeIconSize,
            height: responsive.largeIconSize,
            colorFilter: ColorFilter.mode(colors.gray0, BlendMode.srcIn),
          ),
        ),
        SizedBox(height: 10 * responsive.scaleFactor),
        Text(
          '의미를 가리고 기억해 보세요.\n생각이 안나면 커버를 조금 내려\n확인하고 다음 카드로 넘기세요!',
          style: Typo.bodyStrong(context, color: colors.gray0),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildKnownBadge(BuildContext context, ThemeColors colors, _ResponsiveHelper responsive) {
    return Positioned(
      top: 0,
      right: 0,
      child: Semantics(
        identifier: 'concept-known-toggle',
        label: widget.isKnown ? '안다 해제' : '안다',
        button: true,
        child: GestureDetector(
        onTap: widget.isKnown ? widget.onUnmarkKnown : widget.onKnown,
        child: Container(
          width: responsive.badgeWidth,
          height: responsive.badgeHeight,
          padding: EdgeInsets.symmetric(horizontal: 9 * responsive.scaleFactor, vertical: 6 * responsive.scaleFactor),
          decoration: BoxDecoration(
            color: colors.primaryNormal,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10 * responsive.scaleFactor),
              bottomLeft: Radius.circular(12 * responsive.scaleFactor),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.icons.check.svg(
                width: responsive.largeIconSize,
                height: responsive.largeIconSize,
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
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context, ThemeColors colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.primaryNormal.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.primaryNormal,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
