/// Shared responsive-layout breakpoints and sizing helpers, so every page
/// and widget adapts to the available width instead of assuming a fixed
/// desktop viewport (the platform is reached via a shared link and must
/// work on phones, tablets, and desktops alike).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1000;

  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) => width >= mobileBreakpoint && width < tabletBreakpoint;

  /// Horizontal page padding: tight on phones, generous on desktop.
  static double pagePadding(double width) {
    if (isMobile(width)) return 12;
    if (isTablet(width)) return 20;
    return 24;
  }

  /// Caps line length on very wide monitors; unconstrained (full width,
  /// modulo padding) on anything narrower than a small desktop.
  static double? maxContentWidth(double width) => width > 1100 ? 960 : null;

  /// Width for one field in an N-up responsive field row: a single full-
  /// width column on phones, N even columns above the mobile breakpoint.
  static double fieldWidth(double availableWidth, {int columns = 2, double spacing = 16}) {
    if (isMobile(availableWidth)) return availableWidth;
    final usable = availableWidth - spacing * (columns - 1);
    return usable / columns;
  }
}

/// Lays out [children] as even-width columns that collapse to a single
/// full-width column on narrow (mobile) viewports.
class ResponsiveFieldRow extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  const ResponsiveFieldRow({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = Responsive.fieldWidth(
          constraints.maxWidth,
          columns: columns,
          spacing: spacing,
        );
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
