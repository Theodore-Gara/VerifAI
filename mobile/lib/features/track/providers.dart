import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Track milestones with live progress (GET /api/achievements/milestones).
final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getMilestones();
});
