import 'package:flutter/material.dart';

/// Lets screens hosted by [MainNavShell] open the shared navigation drawer.
final GlobalKey<ScaffoldState> verifaiMainScaffoldKey =
    GlobalKey<ScaffoldState>();

void openVerifaiNavigationDrawer() {
  verifaiMainScaffoldKey.currentState?.openDrawer();
}
