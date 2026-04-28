import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/data/repositories/catalog/catalog_repository.dart';
import 'package:kkeutgong_mobile/domain/models/home/certificate.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class OnboardingCertificateSelectPage extends StatefulWidget {
  const OnboardingCertificateSelectPage({super.key});

  @override
  State<OnboardingCertificateSelectPage> createState() =>
      _OnboardingCertificateSelectPageState();
}

class _OnboardingCertificateSelectPageState
    extends State<OnboardingCertificateSelectPage> {
  String? _selectedId;

  // Catalog is fetched fresh so any cert added on the backend appears here
  // without a mobile release.
  final CatalogRepository _catalog = CatalogRepository();
  List<Certificate> _certificates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final certs = await _catalog.getCertificates();
      if (!mounted) return;
      setState(() {
        _certificates = certs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '자격증 목록을 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  Widget _iconFor(String iconName, ThemeColors colors) {
    switch (iconName) {
      case 'desktop_mac':
        return Assets.icons.desktopMac.svg(
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      case 'menu_book':
        return Assets.icons.menuBook.svg(
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      default:
        return Assets.icons.memory.svg(
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.08;

    return Scaffold(
      backgroundColor: colors.gray10,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        leading: IconButton(
          icon: Assets.icons.arrowBackIos.svg(
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _buildProgressBar(colors, screenWidth, 0.25),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '어떤 자격증을\n준비중인지 알려주세요',
                    style: TextStyle(
                      fontFamily: 'SeoulAlrim',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      letterSpacing: -0.6,
                      color: colors.gray900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Assets.icons.infoFill.svg(
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(colors.gray300, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '나중에 다른 자격증도 공부할 수 있어요.',
                        style: Typo.labelRegular(context, color: colors.gray300),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: Typo.bodyRegular(context, color: colors.gray500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadCertificates,
                            child: Text(
                              '다시 시도',
                              style: Typo.bodyRegular(context, color: colors.primaryNormal),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._certificates.map((cert) {
                      final isSelected = _selectedId == cert.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Semantics(
                          button: true,
                          identifier: 'onboarding-cert-${cert.id}',
                          label: cert.name,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedId = cert.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primaryLight
                                    : colors.gray0,
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primaryNormal
                                      : colors.gray30,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colors.primaryNormal
                                              .withValues(alpha: 0.10),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  _iconFor(cert.icon, colors),
                                  const SizedBox(width: 8),
                                  Text(
                                    cert.name,
                                    style: Typo.bodyRegular(context,
                                        color: colors.gray900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 32),
            child: CustomButton(
              text: '계속하기',
              size: ButtonSize.large,
              theme: CustomButtonTheme.grayscale,
              disabled: _selectedId == null,
              width: double.infinity,
              onPressed: _selectedId == null
                  ? null
                  : () => Get.toNamed(
                        AppRoutes.onboardingExamDate,
                        arguments: {'certificateId': _selectedId},
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      ThemeColors colors, double screenWidth, double progress) {
    final maxWidth = screenWidth - 15 - 56;
    return Container(
      height: 12,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: maxWidth * progress,
            height: 12,
            decoration: BoxDecoration(
              color: colors.primaryNormal,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
