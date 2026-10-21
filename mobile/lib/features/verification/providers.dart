import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// One task per difficulty band. The dashboard only carries a single next task,
/// so the Verification hub asks each band directly — the backend defaults to the
/// verification feature and rotates exhausted bands into practice.
final verificationTasksProvider =
    FutureProvider.autoDispose<List<DailyTask>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final tasks = await Future.wait([
    for (final difficulty in const ['easy', 'medium', 'hard'])
      api.getNextTask(difficulty: difficulty),
  ]);
  return [
    for (final task in tasks)
      if (task != null) task
  ];
});
