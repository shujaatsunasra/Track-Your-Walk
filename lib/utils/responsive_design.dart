import 'package:flutter/material.dart';

/// Million-dollar responsive design system for consistent layouts
class ResponsiveDesign {
  /// Screen size breakpoints
  static const double compactWidthBreakpoint = 360;
  static const double compactHeightBreakpoint = 700;
  static const double mediumWidthBreakpoint = 420;
  static const double largeWidthBreakpoint = 840;

  /// Get screen size category
  static ScreenSizeCategory getScreenSize(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (size.width < compactWidthBreakpoint ||
        size.height < compactHeightBreakpoint) {
      return ScreenSizeCategory.compact;
    } else if (size.width > mediumWidthBreakpoint || size.height > 900) {
      return ScreenSizeCategory.large;
    }
    return ScreenSizeCategory.medium;
  }

  /// Get responsive spacing based on screen size
  static ResponsiveSpacing getSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSizeCategory.compact:
        return ResponsiveSpacing.compact();
      case ScreenSizeCategory.large:
        return ResponsiveSpacing.large();
      case ScreenSizeCategory.medium:
        return ResponsiveSpacing.medium();
    }
  }

  /// Get responsive font scaling
  static double getFontScale(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSizeCategory.compact:
        return 0.9;
      case ScreenSizeCategory.large:
        return 1.1;
      case ScreenSizeCategory.medium:
        return 1.0;
    }
  }

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double factor = 1.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    final basePadding = width * 0.05; // 5% of screen width
    final clampedPadding = basePadding.clamp(16.0, 32.0) * factor;

    return EdgeInsets.symmetric(horizontal: clampedPadding);
  }

  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(
    BuildContext context, {
    double factor = 1.0,
  }) {
    final spacing = getSpacing(context);
    return EdgeInsets.all(spacing.medium * factor);
  }

  /// Get adaptive component size
  static double getAdaptiveSize(
    BuildContext context,
    double baseSize, {
    double minSize = 0.8,
    double maxSize = 1.2,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSizeCategory.compact:
        return baseSize * minSize;
      case ScreenSizeCategory.large:
        return baseSize * maxSize;
      case ScreenSizeCategory.medium:
        return baseSize;
    }
  }
}

/// Screen size categories
enum ScreenSizeCategory { compact, medium, large }

/// Responsive spacing values
class ResponsiveSpacing {
  final double tiny;
  final double small;
  final double medium;
  final double large;
  final double huge;

  const ResponsiveSpacing({
    required this.tiny,
    required this.small,
    required this.medium,
    required this.large,
    required this.huge,
  });

  factory ResponsiveSpacing.compact() {
    return const ResponsiveSpacing(
      tiny: 4,
      small: 8,
      medium: 12,
      large: 16,
      huge: 24,
    );
  }

  factory ResponsiveSpacing.medium() {
    return const ResponsiveSpacing(
      tiny: 6,
      small: 12,
      medium: 16,
      large: 20,
      huge: 32,
    );
  }

  factory ResponsiveSpacing.large() {
    return const ResponsiveSpacing(
      tiny: 8,
      small: 16,
      medium: 20,
      large: 24,
      huge: 40,
    );
  }
}

/// Responsive container widget
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? factor;
  final bool useAdaptivePadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.factor = 1.0,
    this.useAdaptivePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: useAdaptivePadding
          ? ResponsiveDesign.getResponsivePadding(
              context,
              factor: factor ?? 1.0,
            )
          : padding,
      margin:
          margin ??
          ResponsiveDesign.getResponsiveMargin(context, factor: factor ?? 1.0),
      child: child,
    );
  }
}

/// Responsive text widget with automatic scaling
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveDesign.getFontScale(context);
    final adaptedStyle = style?.copyWith(
      fontSize: (style?.fontSize ?? 14) * fontScale,
    );

    return Text(
      text,
      style: adaptedStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive sized box
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const ResponsiveSizedBox({super.key, this.width, this.height, this.child});

  factory ResponsiveSizedBox.height(BuildContext context, double baseHeight) {
    final adaptiveHeight = ResponsiveDesign.getAdaptiveSize(
      context,
      baseHeight,
    );
    return ResponsiveSizedBox(height: adaptiveHeight);
  }

  factory ResponsiveSizedBox.width(BuildContext context, double baseWidth) {
    final adaptiveWidth = ResponsiveDesign.getAdaptiveSize(context, baseWidth);
    return ResponsiveSizedBox(width: adaptiveWidth);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}

/// Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double childAspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveDesign.getSpacing(context);
    final screenSize = ResponsiveDesign.getScreenSize(context);

    final adaptiveCrossAxisCount =
        crossAxisCount ?? _getDefaultCrossAxisCount(screenSize);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: adaptiveCrossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing ?? spacing.medium,
      crossAxisSpacing: crossAxisSpacing ?? spacing.medium,
      children: children,
    );
  }

  int _getDefaultCrossAxisCount(ScreenSizeCategory screenSize) {
    switch (screenSize) {
      case ScreenSizeCategory.compact:
        return 1;
      case ScreenSizeCategory.medium:
        return 2;
      case ScreenSizeCategory.large:
        return 3;
    }
  }
}

/// Breakpoint helper widget
class BreakpointBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSizeCategory screenSize)
  builder;

  const BreakpointBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveDesign.getScreenSize(context);
    return builder(context, screenSize);
  }
}

/// Mixin for responsive widgets
mixin ResponsiveMixin<T extends StatefulWidget> on State<T> {
  ScreenSizeCategory get screenSize => ResponsiveDesign.getScreenSize(context);
  ResponsiveSpacing get spacing => ResponsiveDesign.getSpacing(context);
  double get fontScale => ResponsiveDesign.getFontScale(context);

  bool get isCompact => screenSize == ScreenSizeCategory.compact;
  bool get isMedium => screenSize == ScreenSizeCategory.medium;
  bool get isLarge => screenSize == ScreenSizeCategory.large;

  EdgeInsets get responsivePadding =>
      ResponsiveDesign.getResponsivePadding(context);
  EdgeInsets get responsiveMargin =>
      ResponsiveDesign.getResponsiveMargin(context);

  double adaptiveSize(double baseSize) =>
      ResponsiveDesign.getAdaptiveSize(context, baseSize);
}
