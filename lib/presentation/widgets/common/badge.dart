import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

enum BadgeType { normal, circular, circularText }

enum BadgeSize { small, large }

enum BadgeTheme { grayscale, accent, positive, negative }

class Badge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final BadgeSize size;
  final BadgeTheme theme;
  final SvgGenImage? icon;

  const Badge({
    super.key,
    required this.text,
    this.type = BadgeType.normal,
    this.size = BadgeSize.large,
    this.theme = BadgeTheme.grayscale,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colors),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      child: type == BadgeType.circular
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null && type == BadgeType.normal) ...[
                  icon!.svg(
                    width: size == BadgeSize.small ? 12 : 16,
                    height: size == BadgeSize.small ? 12 : 16,
                    colorFilter: ColorFilter.mode(
                      _getTextColor(colors),
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: size == BadgeSize.small ? 2 : 4),
                ],
                Text(
                  text,
                  style: _getTextStyle(context, colors),
                ),
              ],
            ),
    );
  }

  EdgeInsets _getPadding() {
    switch (type) {
      case BadgeType.normal:
        return size == BadgeSize.small
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case BadgeType.circular:
        return EdgeInsets.zero;
      case BadgeType.circularText:
        return size == BadgeSize.small
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : const EdgeInsets.all(4);
    }
  }

  double _getBorderRadius() {
    switch (type) {
      case BadgeType.normal:
        return size == BadgeSize.small ? 4 : 6;
      case BadgeType.circular:
      case BadgeType.circularText:
        return size == BadgeSize.small ? 12 : 14;
    }
  }

  Color _getBackgroundColor(ThemeColors colors) {
    if (type == BadgeType.circular) {
      return _getSolidColor(colors);
    }

    switch (theme) {
      case BadgeTheme.grayscale:
        return colors.gray20;
      case BadgeTheme.accent:
        return colors.primaryLight;
      case BadgeTheme.positive:
        return colors.greenLight;
      case BadgeTheme.negative:
        return colors.redLight;
    }
  }

  Color _getSolidColor(ThemeColors colors) {
    switch (theme) {
      case BadgeTheme.grayscale:
        return colors.gray900;
      case BadgeTheme.accent:
        return colors.primaryNormal;
      case BadgeTheme.positive:
        return colors.greenNormal;
      case BadgeTheme.negative:
        return colors.redNormal;
    }
  }

  Color _getTextColor(ThemeColors colors) {
    if (type == BadgeType.circularText) {
      return _getSolidColor(colors);
    }

    switch (theme) {
      case BadgeTheme.grayscale:
        return colors.gray900;
      case BadgeTheme.accent:
        return colors.primaryNormal;
      case BadgeTheme.positive:
        return colors.greenNormal;
      case BadgeTheme.negative:
        return colors.redNormal;
    }
  }

  TextStyle _getTextStyle(BuildContext context, ThemeColors colors) {
    final style = size == BadgeSize.small
        ? Typo.captionRegular(context)
        : Typo.footnoteRegular(context);

    return style.copyWith(color: _getTextColor(colors));
  }
}
