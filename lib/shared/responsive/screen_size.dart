import 'package:flutter/widgets.dart';

import '../../core/theme/app_breakpoints.dart';

/// Three responsive size buckets.
enum ScreenSize {
  /// Phone portrait and narrow widths.
  compact,

  /// Tablet portrait / small landscape.
  medium,

  /// Desktop / large landscape.
  expanded,
}

extension ScreenSizeX on ScreenSize {
  /// True when this size is at least a tablet.
  bool get isMediumOrLarger =>
      this == ScreenSize.medium || this == ScreenSize.expanded;

  /// True when this size is desktop / wide.
  bool get isExpanded => this == ScreenSize.expanded;
}

/// Resolves a [ScreenSize] from a logical width in pixels.
ScreenSize screenSizeOf(double width) {
  if (width >= AppBreakpoints.expanded) {
    return ScreenSize.expanded;
  }
  if (width >= AppBreakpoints.medium) {
    return ScreenSize.medium;
  }
  return ScreenSize.compact;
}

/// Convenience accessor that uses a [BuildContext]'s screen width.
ScreenSize screenSizeOfContext(BuildContext context) {
  return screenSizeOf(MediaQuery.sizeOf(context).width);
}
