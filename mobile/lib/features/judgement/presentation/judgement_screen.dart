import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/features/judgement/presentation/choice_task_screen.dart';
import 'package:verifai/features/judgement/providers.dart';

class JudgementScreen extends ConsumerWidget {
  const JudgementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceTaskScreen(
      taskProvider: judgementTaskProvider,
      feature: 'judgement',
      categoryLabel: 'AI Judgement',
      decisionPrompt: 'How should AI be used here?',
      reasonPrompt: 'Pick the best reason',
    );
  }
}
