import 'package:flutter/widgets.dart';

import 'screen_size.dart';

/// Builds different widgets based on the available width.
///
/// Example:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, size) => switch (size) {
///     ScreenSize.compact  => const _OneColumn(),
///     ScreenSize.medium   => const _TwoColumns(),
///     ScreenSize.expanded => const _ThreeColumns(),
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, screenSizeOf(constraints.maxWidth));
      },
    );
  }
}
