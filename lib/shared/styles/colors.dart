import 'package:flutter/material.dart';

class ThemeColors {
  final Color gray0;
  final Color gray10;
  final Color gray20;
  final Color gray30;
  final Color gray40;
  final Color gray50;
  final Color gray60;
  final Color gray70;
  final Color gray80;
  final Color gray90;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;
  final Color primaryLight;
  final Color primaryLightHover;
  final Color primaryLightActive;
  final Color primaryNormal;
  final Color primaryNormalHover;
  final Color primaryNormalActive;
  final Color primaryDark;
  final Color primaryDarkHover;
  final Color primaryDarkActive;
  final Color primaryDarker;
  final Color redLight;
  final Color redLightHover;
  final Color redLightActive;
  final Color redNormal;
  final Color redNormalHover;
  final Color redNormalActive;
  final Color redDark;
  final Color redDarkHover;
  final Color redDarkActive;
  final Color redDarker;
  final Color greenLight;
  final Color greenLightHover;
  final Color greenLightActive;
  final Color greenNormal;
  final Color greenNormalHover;
  final Color greenNormalActive;
  final Color greenDark;
  final Color greenDarkHover;
  final Color greenDarkActive;
  final Color greenDarker;



  ThemeColors({
    required this.gray0,
    required this.gray10,
    required this.gray20,
    required this.gray30,
    required this.gray40,
    required this.gray50,
    required this.gray60,
    required this.gray70,
    required this.gray80,
    required this.gray90,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.primaryLight,
    required this.primaryLightHover,
    required this.primaryLightActive,
    required this.primaryNormal,
    required this.primaryNormalHover,
    required this.primaryNormalActive,
    required this.primaryDark,
    required this.primaryDarkHover,
    required this.primaryDarkActive,
    required this.primaryDarker,
    required this.redLight,
    required this.redLightHover,
    required this.redLightActive,
    required this.redNormal,
    required this.redNormalHover,
    required this.redNormalActive,
    required this.redDark,
    required this.redDarkHover,
    required this.redDarkActive,
    required this.redDarker,
    required this.greenLight,
    required this.greenLightHover,
    required this.greenLightActive,
    required this.greenNormal,
    required this.greenNormalHover,
    required this.greenNormalActive,
    required this.greenDark,
    required this.greenDarkHover,
    required this.greenDarkActive,
    required this.greenDarker,
  });

  static ThemeColors of(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ThemeColors(
      gray0: isDarkMode ? const Color(0xff000000) : const Color(0xffFFFFFF),
      gray10: isDarkMode ? const Color(0xff0D0D0D) : const Color(0xffFAFAFA),
      gray20: isDarkMode ? const Color(0xff1C1C1C) : const Color(0xffF5F5F5),
      gray30: isDarkMode ? const Color(0xff2E2E2E) : const Color(0xffEBEBEB),
      gray40: isDarkMode ? const Color(0xff3B3B3B) : const Color(0xffDEDEDE),
      gray50: isDarkMode ? const Color(0xff4A4A4A) : const Color(0xffBFBFBF),
      gray60: isDarkMode ? const Color(0xff575757) : const Color(0xffB0B0B0),
      gray70: isDarkMode ? const Color(0xff666666) : const Color(0xffA3A3A3),
      gray80: isDarkMode ? const Color(0xff757575) : const Color(0xff949494),
      gray90: isDarkMode ? const Color(0xff858585) : const Color(0xff858585),
      gray100: isDarkMode ? const Color(0xff949494) : const Color(0xff757575),
      gray200: isDarkMode ? const Color(0xffA3A3A3) : const Color(0xff666666),
      gray300: isDarkMode ? const Color(0xffB0B0B0) : const Color(0xff575757),
      gray400: isDarkMode ? const Color(0xffBFBFBF) : const Color(0xff4A4A4A),
      gray500: isDarkMode ? const Color(0xffDEDEDE) : const Color(0xff3B3B3B),
      gray600: isDarkMode ? const Color(0xffEBEBEB) : const Color(0xff2E2E2E),
      gray700: isDarkMode ? const Color(0xffF5F5F5) : const Color(0xff1C1C1C),
      gray800: isDarkMode ? const Color(0xffFAFAFA) : const Color(0xff0D0D0D),
      gray900: isDarkMode ? const Color(0xffFFFFFF) : const Color(0xff000000),
      primaryLight: const Color(0xffECF0FC),
      primaryLightHover: const Color(0xffE3E9FB),
      primaryLightActive: const Color(0xffC4D1F6),
      primaryNormal: const Color(0xff4169E1),
      primaryNormalHover: const Color(0xff3B5FCB),
      primaryNormalActive: const Color(0xff3454B4),
      primaryDark: const Color(0xff314FA9),
      primaryDarkHover: const Color(0xff273F87),
      primaryDarkActive: const Color(0xff1D2F65),
      primaryDarker: const Color(0xff17254F),
      redLight: const Color(0xffFFECEB),
      redLightHover: const Color(0xffFFE2E1),
      redLightActive: const Color(0xffFFC4C0),
      redNormal: const Color(0xffFF4035),
      redNormalHover: const Color(0xffE63A30),
      redNormalActive: const Color(0xffCC332A),
      redDark: const Color(0xffBF3028),
      redDarkHover: const Color(0xff992620),
      redDarkActive: const Color(0xff731D18),
      redDarker: const Color(0xff591613),
      greenLight: const Color(0xffEBFAEE),
      greenLightHover: const Color(0xffE0F7E6),
      greenLightActive: const Color(0xffBFEFCB),
      greenNormal: const Color(0xff32CC58),
      greenNormalHover: const Color(0xff2DB84F),
      greenNormalActive: const Color(0xff28A346),
      greenDark: const Color(0xff269942),
      greenDarkHover: const Color(0xff1E7A35),
      greenDarkActive: const Color(0xff165C28),
      greenDarker: const Color(0xff12471F),
    );
  }
}