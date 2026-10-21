import 'package:flutter/material.dart';

/// Lets screens hosted by [MainNavShell] open the shared navigation drawer.
///
/// The drawer is a secondary navigation source: the bottom dock carries the five
/// areas, and the drawer lists every destination underneath them in one place.
final GlobalKey<ScaffoldState> verifaiMainScaffoldKey =
    GlobalKey<ScaffoldState>();

void openVerifaiNavigationDrawer() {
  verifaiMainScaffoldKey.currentState?.openDrawer();
}

/// Switches the dock tab of the currently mounted [MainNavShell].
///
/// The five dock areas are separate GoRoutes, each building its own shell. When
/// one shell `go`s to a sibling route, two shells exist at once and both carry
/// [verifaiMainScaffoldKey] — a global key can only live on one widget at a time,
/// so the second navigation throws and the hub never opens. Any in-app link that
/// targets a dock area (quick-launch tiles, drawer, wellness menu) must therefore
/// switch tabs here instead of pushing or going to a sibling shell route.
typedef ShellTabSwitcher = void Function(int index);

ShellTabSwitcher? _tabSwitcher;

/// Called by [MainNavShell] while it is mounted, so the current shell owns the
/// switch. A single mounted shell at a time keeps this a plain field.
void registerShellTabSwitcher(ShellTabSwitcher switcher) {
  _tabSwitcher = switcher;
}

void unregisterShellTabSwitcher() {
  _tabSwitcher = null;
}

/// Switches to a dock area by index (Home 0 … Profile 4). No-op when no shell is
/// mounted, so callers never need to know whether they are inside the shell.
void switchShellTab(int index) => _tabSwitcher?.call(index);

