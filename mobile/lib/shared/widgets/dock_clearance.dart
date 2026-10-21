import 'package:flutter/widgets.dart';

/// The floating navigation dock's height at the default text scale.
const double kDockHeight = 64;

/// Space to leave at the bottom of a scroll view so its last item clears the
/// floating dock.
///
/// Screens used to hardcode `100` (and two used `110`), which was right for one
/// device at one text scale: the dock is 64 dp tall, sits above the home
/// indicator, and its labels grow with the OS text setting. Both parts are now
/// derived from the actual media query.
double dockClearance(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return kDockHeight + 16;
  final scale = media.textScaler.scale(1.0).clamp(1.0, 1.3);
  return kDockHeight * scale + media.padding.bottom + 16;
}
