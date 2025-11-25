import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/custom_button.dart';
import 'package:kkeutgong_mobile/presentation/widgets/common/skeleton.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

Widget buildCurriculumSkeletonLoading(
  BuildContext context,
  ThemeColors colors,
  double scale,
  double horizontalPadding,
) {
  return SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 134 * scale,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24 * scale,
              horizontalPadding,
              18 * scale,
            ),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final isActive = index == 0;
              return Opacity(
                opacity: isActive ? 1 : 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.gray0,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.gray70),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 28 * scale,
                            vertical: 12 * scale,
                          ),
                          child: Assets.icons.memory.svg(
                            width: 36 * scale,
                            height: 36 * scale,
                            colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Skeleton(
                      width: 80 * scale,
                      height: 16 * scale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => SizedBox(width: 30 * scale),
            itemCount: 3,
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.gray0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.gray0,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.fromLTRB(24 * scale, 15 * scale, 24 * scale, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Skeleton(
                                    width: 120 * scale,
                                    height: 24 * scale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  SizedBox(height: 4 * scale),
                                  Skeleton(
                                    width: 50 * scale,
                                    height: 20 * scale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8 * scale),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 151 * scale,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: colors.gray50,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3 * scale),
                                  Skeleton(
                                    width: 35 * scale,
                                    height: 16 * scale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        CustomButton(
                          text: '모의고사 보기',
                          size: ButtonSize.medium,
                          theme: CustomButtonTheme.primary,
                          disabled: true,
                          onPressed: null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  for (int i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(height: 60),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: colors.gray300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Skeleton(
                                  width: 100 * scale,
                                  height: 18 * scale,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Expanded(child: Container(height: 1, color: colors.gray300)),
                            ],
                          ),
                          SizedBox(height: 20 * scale),
                          for (int j = 0; j < 3; j++) ...[
                            if (j > 0)
                              Center(
                                child: Container(
                                  width: 3,
                                  height: 23,
                                  decoration: BoxDecoration(
                                    color: colors.gray70,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: colors.gray0,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.gray70),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.gray70,
                                    offset: const Offset(0, 2),
                                    blurRadius: 0,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${j + 1}.',
                                          style: Typo.titleStrong(context, color: colors.gray900),
                                        ),
                                        SizedBox(width: 32 * scale),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Skeleton(
                                                width: double.infinity,
                                                height: 22 * scale,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              SizedBox(height: 8 * scale),
                                              Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: colors.primaryLight,
                                                  borderRadius: BorderRadius.circular(99),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 32 * scale),
                                  CustomButton(
                                    text: '시작',
                                    size: ButtonSize.small,
                                    theme: CustomButtonTheme.grayscale,
                                    disabled: true,
                                    onPressed: null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
