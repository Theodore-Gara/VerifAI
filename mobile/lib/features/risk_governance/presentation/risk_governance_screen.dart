import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/features/judgement/presentation/choice_task_screen.dart';
import 'package:verifai/features/risk_governance/providers.dart';

class RiskGovernanceScreen extends ConsumerWidget {
  const RiskGovernanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceTaskScreen(
      taskProvider: riskGovernanceTaskProvider,
      feature: 'risk_governance',
      categoryLabel: 'Risk & Governance',
      decisionPrompt: 'What should you do?',
      reasonPrompt: 'Pick the best reason',
    );
  }
}
