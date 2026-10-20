import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: VerifAIApp()));
}

class VerifAIApp extends ConsumerWidget {
  const VerifAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final palette = paletteFor(mode, platformBrightness);

    // `AppColors` reads from the active palette, so every existing reference in
    // the widget tree follows the chosen mode without being rewritten.
    AppColors.palette = palette;

    return MaterialApp.router(
      title: 'VerifAI',
      theme: AppTheme.themeFor(palette),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
