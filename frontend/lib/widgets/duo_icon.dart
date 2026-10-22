import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The app's own icons, in the playful "duotone" style: a rounded outline
/// plus the same colour as a soft 20% fill.
enum AppIcon {
  back,
  forward,
  down,
  chevronDown,
  send,
  check,
  alert,
  pencil,
  cloudOff,
  wifiOff,
  list,
  key,
  globe,
  lock,
  logout,
  book,
  bell,
  clock,
  settings,
  chart,
  star,
  sparkle,
  sun,
}

const _soft = 'fill="currentColor" fill-opacity="0.2"';

/// The inside of each 24 x 24 icon (SVG shapes).
const Map<AppIcon, String> _shapes = {
  AppIcon.back: '<path d="M15 5l-7 7 7 7"/>',
  AppIcon.forward: '<path d="M5 12h14M13 6l6 6-6 6"/>',
  AppIcon.down: '<path d="M12 5v14M6 13l6 6 6-6"/>',
  AppIcon.chevronDown: '<path d="M6 9l6 6 6-6"/>',
  AppIcon.send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
  AppIcon.check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  AppIcon.alert:
      '<circle cx="12" cy="12" r="9" $_soft/><path d="M12 7.5v5.5M12 16.5v.1"/>',
  AppIcon.pencil:
      '<path d="M4 20l1-4L16 5l3 3L8 19z" $_soft/><path d="M14 7l3 3"/>',
  AppIcon.cloudOff:
      '<path d="M7 18h10a4 4 0 0 0 .6-7.95A6 6 0 0 0 6.3 9.1 4.5 4.5 0 0 0 7 18z" $_soft/><path d="M4 4l16 16"/>',
  AppIcon.wifiOff:
      '<path d="M5 12.5a10 10 0 0 1 4-2.3M2 9a14 14 0 0 1 5.5-3.3M19 12.5a10 10 0 0 0-2-1.5M22 9a14 14 0 0 0-8.5-3.9M8.5 16a5 5 0 0 1 7 0"/><circle cx="12" cy="19.5" r="1.2" fill="currentColor"/><path d="M4 4l16 16"/>',
  AppIcon.list:
      '<rect x="3" y="4" width="18" height="16" rx="4" $_soft/><path d="M8 9h8M8 12h8M8 15h5"/>',
  AppIcon.key:
      '<circle cx="8" cy="15" r="4" $_soft/><path d="M11 12l8-8M16 7l2 2M14 9l2 2"/>',
  AppIcon.globe:
      '<circle cx="12" cy="12" r="9" $_soft/><path d="M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18"/>',
  AppIcon.lock:
      '<rect x="5" y="10" width="14" height="10" rx="3" $_soft/><path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v2"/>',
  AppIcon.logout:
      '<path d="M10 4H7a3 3 0 0 0-3 3v10a3 3 0 0 0 3 3h3" $_soft/><path d="M15 8l4 4-4 4M19 12H10"/>',
  AppIcon.book:
      '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H19v15H6.5A2.5 2.5 0 0 0 4 20.5z" $_soft/><path d="M4 20.5V5.5M8 7h7M4 20.5A2.5 2.5 0 0 1 6.5 18H19v3H6.5"/>',
  AppIcon.bell:
      '<path d="M12 3a6 6 0 0 1 6 6c0 2.5-1.5 3.8-2.5 5H8.5C7.5 12.8 6 11.5 6 9a6 6 0 0 1 6-6z" $_soft/><path d="M9.5 18h5M10.5 21h3"/>',
  AppIcon.clock:
      '<circle cx="12" cy="13" r="8" $_soft/><path d="M12 9v4l2.5 2M9 2h6"/>',
  AppIcon.settings:
      '<path d="M12 3l2.2 1.3 2.5-.3 1 2.3 2.1 1.4-.4 2.5L20.5 12l-1.1 2.3.4 2.5-2.1 1.4-1 2.3-2.5-.3L12 21l-2.2-1.3-2.5.3-1-2.3-2.1-1.4.4-2.5L3.5 12l1.1-2.3-.4-2.5 2.1-1.4 1-2.3 2.5.3z" $_soft/><circle cx="12" cy="12" r="3"/>',
  AppIcon.chart:
      '<rect x="3" y="3" width="18" height="18" rx="5" $_soft/><path d="M7 15l3-3 3 2 4-5"/>',
  AppIcon.star:
      '<path d="M12 3.5l2.6 5.3 5.8.8-4.2 4.1 1 5.8L12 16.8l-5.2 2.7 1-5.8-4.2-4.1 5.8-.8z" $_soft/>',
  AppIcon.sun:
      '<circle cx="12" cy="12" r="4.5" $_soft/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
  AppIcon.sparkle:
      '<path d="M12 3l2 5.5L19.5 10 14 12l-2 6-2-6-5.5-2L10 8.5z" $_soft/><path d="M19 16l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z"/>',
};

/// Arrows and ticks are drawn a little bolder, as they have no fill.
const _bold = {
  AppIcon.back,
  AppIcon.forward,
  AppIcon.down,
  AppIcon.chevronDown,
  AppIcon.send,
  AppIcon.check,
};

/// Shows one [AppIcon]. Used like Flutter's `Icon`: the colour comes from
/// [color], or else from the surrounding icon theme.
///
/// PERFORMANCE: each icon is a tiny vector; flutter_svg reads each one
/// once and keeps it, so lists of icons stay cheap.
class DuoIcon extends StatelessWidget {
  const DuoIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final AppIcon icon;
  final double? size;
  final Color? color;

  /// What a screen reader says. Leave empty when words are already beside it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    final color = this.color ?? theme.color ?? const Color(0xFF000000);
    final width = _bold.contains(icon) ? 2.4 : 1.8;

    final svg =
        '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" '
        'fill="none" stroke="currentColor" stroke-width="$width" '
        'stroke-linecap="round" stroke-linejoin="round">${_shapes[icon]}</svg>';

    final picture = SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      excludeFromSemantics: true,
    );

    if (semanticLabel == null) return ExcludeSemantics(child: picture);
    return Semantics(label: semanticLabel, image: true, child: picture);
  }
}
