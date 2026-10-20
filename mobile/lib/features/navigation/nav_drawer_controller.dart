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
