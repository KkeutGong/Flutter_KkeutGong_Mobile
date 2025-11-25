import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

enum ButtonSize { small, medium, large }

enum CustomButtonTheme { grayscale, primary }

class CustomButton extends StatelessWidget {
  final String text;
  final ButtonSize size;
  final CustomButtonTheme theme;
  final bool disabled;
  final SvgGenImage? leftIcon;
  final SvgGenImage? rightIcon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool useDefaultIconColor;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.size = ButtonSize.large,
    this.theme = CustomButtonTheme.primary,
    this.disabled = false,
    this.leftIcon,
    this.rightIcon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.useDefaultIconColor = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Opacity(
      opacity: disabled ? 0.3 : 1.0,
      child: SizedBox(
        width: width,
        child: Material(
          color: _getBackgroundColor(colors),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            child: Container(
              padding: _getPadding(),
              child: Row(
                mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leftIcon != null) ...[
                    _buildIcon(leftIcon!, colors),
                    SizedBox(width: _getGap()),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: _getTextStyle(context, colors),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (rightIcon != null) ...[
                    SizedBox(width: _getGap()),
                    _buildIcon(rightIcon!, colors),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 6;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getGap() {
    switch (size) {
      case ButtonSize.small:
        return 4;
      case ButtonSize.medium:
        return 6;
      case ButtonSize.large:
        return 8;
    }
  }

  Widget _buildIcon(SvgGenImage icon, ThemeColors colors) {
    if (useDefaultIconColor) {
      return icon.svg(
        width: _getIconSize(),
        height: _getIconSize(),
      );
    }
    
    return icon.svg(
      width: _getIconSize(),
      height: _getIconSize(),
      colorFilter: ColorFilter.mode(
        iconColor ?? _getTextColor(colors),
        BlendMode.srcIn,
      ),
    );
  }

  Color _getBackgroundColor(ThemeColors colors) {
    if (backgroundColor != null) return backgroundColor!;
    
    switch (theme) {
      case CustomButtonTheme.grayscale:
        return colors.gray900;
      case CustomButtonTheme.primary:
        return colors.primaryNormal;
    }
  }

  Color _getTextColor(ThemeColors colors) {
    if (textColor != null) return textColor!;
    return colors.gray0;
  }

  TextStyle _getTextStyle(BuildContext context, ThemeColors colors) {
    TextStyle style;
    switch (size) {
      case ButtonSize.small:
        style = Typo.footnoteRegular(context);
        break;
      case ButtonSize.medium:
        style = Typo.labelRegular(context);
        break;
      case ButtonSize.large:
        style = Typo.bodyRegular(context);
        break;
    }

    return style.copyWith(color: _getTextColor(colors));
  }
}
