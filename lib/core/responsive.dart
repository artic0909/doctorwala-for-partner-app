import 'package:flutter/material.dart';

/// Central responsive configuration and breakpoint system for Doctorwala Partner
class AppResponsive {
  // Mobile device breakpoints
  static const double smallMobileWidth = 360.0;
  static const double mobileWidth = 600.0;
  static const double shortScreenHeight = 680.0;

  // Standard mobile canvas reference (iPhone 14/15 / Pixel 7 standard)
  static const double baseWidth = 390.0;
  static const double baseHeight = 844.0;

  /// Returns true if device screen width is smaller than 360dp (e.g., iPhone SE 1st gen, small Galaxy A)
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < smallMobileWidth;

  /// Returns true if device screen height is compact/short (under 680dp)
  static bool isShortScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).height < shortScreenHeight;

  /// Proportional width scaling with safe boundary clamps
  static double scaleWidth(
    BuildContext context,
    double size, {
    double minFactor = 0.85,
    double maxFactor = 1.25,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / baseWidth).clamp(minFactor, maxFactor);
    return size * scale;
  }

  /// Proportional height scaling with safe boundary clamps
  static double scaleHeight(
    BuildContext context,
    double size, {
    double minFactor = 0.85,
    double maxFactor = 1.25,
  }) {
    final height = MediaQuery.sizeOf(context).height;
    final scale = (height / baseHeight).clamp(minFactor, maxFactor);
    return size * scale;
  }

  /// Safe proportional font sizing that preserves readability without overflow
  static double scaleFont(
    BuildContext context,
    double fontSize, {
    double minFactor = 0.88,
    double maxFactor = 1.15,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / baseWidth).clamp(minFactor, maxFactor);
    return fontSize * scale;
  }

  /// Standard responsive horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < smallMobileWidth) return 16.0;
    if (width < 400.0) return 22.0;
    return 28.0;
  }

  /// Responsive value switcher
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? smallMobile,
    T? shortScreen,
  }) {
    final size = MediaQuery.sizeOf(context);
    if (smallMobile != null && size.width < smallMobileWidth) {
      return smallMobile;
    }
    if (shortScreen != null && size.height < shortScreenHeight) {
      return shortScreen;
    }
    return mobile;
  }
}

/// Handy extension on [BuildContext] for responsive styling across all screens
extension ResponsiveContext on BuildContext {
  /// Current screen width
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Current screen height
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// System safe area padding
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);

  /// True if device screen width is compact (<360dp)
  bool get isSmallMobile => screenWidth < AppResponsive.smallMobileWidth;

  /// True if device screen height is compact (<680dp)
  bool get isShortScreen => screenHeight < AppResponsive.shortScreenHeight;

  /// Width percentage (e.g. context.wp(90) = 90% screen width)
  double wp(double percent) => screenWidth * (percent / 100);

  /// Height percentage (e.g. context.hp(50) = 50% screen height)
  double hp(double percent) => screenHeight * (percent / 100);

  /// Scaled font size with safe boundary
  double sp(double size, {double minFactor = 0.88, double maxFactor = 1.15}) =>
      AppResponsive.scaleFont(this, size, minFactor: minFactor, maxFactor: maxFactor);

  /// Scaled width
  double sw(double size) => AppResponsive.scaleWidth(this, size);

  /// Scaled height
  double sh(double size) => AppResponsive.scaleHeight(this, size);

  /// Adaptive horizontal page margin
  double get responsiveHorizontalPadding => AppResponsive.horizontalPadding(this);

  /// Switch value based on screen profile
  T responsive<T>({
    required T mobile,
    T? smallMobile,
    T? shortScreen,
  }) =>
      AppResponsive.value(
        this,
        mobile: mobile,
        smallMobile: smallMobile,
        shortScreen: shortScreen,
      );
}
