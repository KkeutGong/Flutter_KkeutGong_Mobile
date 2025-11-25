import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

enum TextButtonSize { small, medium, large }

enum CustomTextButtonTheme { grayscale, accent, negative, positive }

class CustomTextButton extends StatelessWidget {
  final String text;
  final TextButtonSize size;
  final CustomTextButtonTheme theme;
  final bool disabled;
  final SvgGenImage? leftIcon;
  final SvgGenImage? rightIcon;
  final VoidCallback? onPressed;

  const CustomTextButton({
    super.key,
    required this.text,
    this.size = TextButtonSize.large,
    this.theme = CustomTextButtonTheme.grayscale,
    this.disabled = false,
    this.leftIcon,
    this.rightIcon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Opacity(
      opacity: disabled ? 0.3 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leftIcon != null) ...[
                leftIcon!.svg(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  colorFilter: ColorFilter.mode(
                    _getTextColor(colors),
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: _getGap()),
              ],
              Text(
                text,
                style: _getTextStyle(context, colors),
              ),
              if (rightIcon != null) ...[
                SizedBox(width: _getGap()),
                rightIcon!.svg(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  colorFilter: ColorFilter.mode(
                    _getTextColor(colors),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case TextButtonSize.small:
        return 16;
      case TextButtonSize.medium:
        return 20;
      case TextButtonSize.large:
        return 24;
    }
  }

  double _getGap() {
    switch (size) {
      case TextButtonSize.small:
        return 4;
      case TextButtonSize.medium:
        return 6;
      case TextButtonSize.large:
        return 8;
    }
  }

  Color _getTextColor(ThemeColors colors) {
    switch (theme) {
      case CustomTextButtonTheme.grayscale:
        return colors.gray900;
      case CustomTextButtonTheme.accent:
        return colors.primaryNormal;
      case CustomTextButtonTheme.negative:
        return colors.redLight;
      case CustomTextButtonTheme.positive:
        return colors.greenLight;
    }
  }

  TextStyle _getTextStyle(BuildContext context, ThemeColors colors) {
    TextStyle style;
    switch (size) {
      case TextButtonSize.small:
        style = Typo.footnoteRegular(context);
        break;
      case TextButtonSize.medium:
        style = Typo.labelRegular(context);
        break;
      case TextButtonSize.large:
        style = Typo.bodyRegular(context);
        break;
    }

    return style.copyWith(color: _getTextColor(colors));
  }
}
