import 'package:flutter/material.dart';

class Typo {
  static const String fontFamily = 'Pretendard';

  static TextStyle displayRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 48,
      fontWeight: FontWeight.w500,
      height: 64 / 48,
      letterSpacing: -1.44,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle displayStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 64 / 48,
      letterSpacing: -1.44,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle titleRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w500,
      height: 32 / 24,
      letterSpacing: -0.48,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle titleStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 32 / 24,
      letterSpacing: -0.48,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle headingRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 28 / 20,
      letterSpacing: -0.4,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle headingStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 28 / 20,
      letterSpacing: -0.4,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle bodyRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 24 / 16,
      letterSpacing: -0.32,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle bodyStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 24 / 16,
      letterSpacing: -0.32,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle labelRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 22 / 14,
      letterSpacing: -0.28,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle labelStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 22 / 14,
      letterSpacing: -0.28,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle footnoteRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 20 / 12,
      letterSpacing: -0.24,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle footnoteStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 20 / 12,
      letterSpacing: -0.24,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle captionRegular(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 16 / 10,
      letterSpacing: -0.2,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }

  static TextStyle captionStrong(BuildContext context, {Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 16 / 10,
      letterSpacing: -0.2,
      color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
    );
  }
}