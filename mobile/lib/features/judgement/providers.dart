import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// The next AI Judgement task (rotates to practice when all are seen).
final judgementTaskProvider = FutureProvider<DailyTask?>((ref) async {
  return ref.watch(apiClientProvider).getNextTask(feature: 'judgement');
});
