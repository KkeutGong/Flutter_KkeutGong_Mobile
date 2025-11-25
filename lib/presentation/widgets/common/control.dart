import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

enum ControlType {
  heart,
  star,
  toggle,
  check,
  checkFill,
  radio,
}

class Control extends StatelessWidget {
  final ControlType type;
  final bool selected;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  const Control({
    super.key,
    required this.type,
    this.selected = false,
    this.disabled = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Opacity(
      opacity: disabled ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged?.call(!selected),
        child: _buildControl(colors),
      ),
    );
  }

  Widget _buildControl(ThemeColors colors) {
    switch (type) {
      case ControlType.heart:
        return selected
            ? Assets.icons.heartFill.svg(
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFF325A),
                  BlendMode.srcIn,
                ),
              )
            : Assets.icons.heart.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colors.gray60,
                  BlendMode.srcIn,
                ),
              );

      case ControlType.star:
        return selected
            ? Assets.icons.starFill.svg(
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFF5C905),
                  BlendMode.srcIn,
                ),
              )
            : Assets.icons.star.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colors.gray60,
                  BlendMode.srcIn,
                ),
              );

      case ControlType.toggle:
        return Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? colors.primaryNormal : colors.gray60,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                selected ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.gray0,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );

      case ControlType.check:
        return selected
            ? Assets.icons.check.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colors.primaryNormal,
                  BlendMode.srcIn,
                ),
              )
            : Assets.icons.check.svg(
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colors.gray60,
                  BlendMode.srcIn,
                ),
              );

      case ControlType.checkFill:
        return Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? colors.primaryNormal : Colors.transparent,
            border: Border.all(
              color: colors.gray60,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: selected
              ? Assets.icons.check.svg(
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    colors.gray0,
                    BlendMode.srcIn,
                  ),
                )
              : null,
        );

      case ControlType.radio:
        return Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? colors.primaryNormal : Colors.transparent,
            border: Border.all(
              color: colors.gray60,
              width: 1,
            ),
            shape: BoxShape.circle,
          ),
          child: selected
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.gray0,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        );
    }
  }
}
