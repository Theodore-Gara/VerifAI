import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/services/resume_refresh.dart';
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

  /// Last palette applied. `AppColors` is static, so widgets that don't
  /// rebuild on their own keep their old-mode colours; when the palette flips
  /// we force a full reassemble so every screen picks it up immediately.
  static AppPalette? _activePalette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final palette = paletteFor(mode, platformBrightness);

    // `AppColors` reads from the active palette, so every existing reference in
    // the widget tree follows the chosen mode without being rewritten.
    final paletteChanged = _activePalette != null && _activePalette != palette;
    AppColors.palette = palette;
    _activePalette = palette;
    if (paletteChanged) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => WidgetsBinding.instance.reassembleApplication(),
      );
    }

    return ResumeRefresh(
      child: MaterialApp.router(
        title: 'VerifAI',
        theme: AppTheme.themeFor(palette),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
