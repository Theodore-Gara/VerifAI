import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// The next Risk & Governance task (rotates to practice when all are seen).
final riskGovernanceTaskProvider = FutureProvider<DailyTask?>((ref) async {
  return ref.watch(apiClientProvider).getNextTask(feature: 'risk_governance');
});
