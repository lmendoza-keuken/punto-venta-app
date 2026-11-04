import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Width-based layout bands (Material-like). Prefer this over Platform checks.
enum LayoutSpec {
  compact,
  medium,
  expanded;

  static const double compactBreakpoint = 700;
  static const double expandedBreakpoint = 1100;

  static LayoutSpec fromWidth(double width) {
    if (width < compactBreakpoint) return LayoutSpec.compact;
    if (width < expandedBreakpoint) return LayoutSpec.medium;
    return LayoutSpec.expanded;
  }

  static LayoutSpec of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  bool get isCompact => this == LayoutSpec.compact;
  bool get isMedium => this == LayoutSpec.medium;
  bool get isExpanded => this == LayoutSpec.expanded;

  /// Rail sidebar for medium/expanded; drawer for compact.
  bool get useNavigationRail => !isCompact;

  /// Side-by-side catalog + cart panel.
  bool get useWidePosShell => !isCompact;
}

class AppDimensions {
  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;

  // Button Heights
  static const double buttonHeightS = 30.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightm = 40.0;
  static const double buttonHeightL = 56.0;

  // Product Card
  static const double productCardWidth = 180.0;
  static const double productCardHeight = 220.0;
  static const double productImageHeight = 120.0;

  // Cart Panel
  static const double cartPanelWidth = 300.0;

  // Category Tab
  static const double categoryTabHeight = 40.0;

  // Navigation
  static const double sidebarRailWidth = 80.0;
  static const double sidebarDrawerWidth = 280.0;

  // Compact scan preview band
  static const double compactPreviewImageSize = 96.0;

  /// Cap dialog preferred width to the current viewport.
  static double dialogWidth(BuildContext context, double preferred) {
    final max = MediaQuery.sizeOf(context).width - paddingL * 2;
    return math.min(preferred, math.max(0, max));
  }
}