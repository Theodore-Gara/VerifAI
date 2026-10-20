import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'shared/widgets/app_feedback_banner.dart';

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

    return MaterialApp.router(
      title: 'VerifAI',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // The overlay host renders every showFeedback(...) banner floating above
      // the active screen, so callers never need their own ScaffoldMessenger.
      // It sits inside MaterialApp so it inherits MediaQuery/Directionality.
      builder: (context, child) =>
          FeedbackOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
