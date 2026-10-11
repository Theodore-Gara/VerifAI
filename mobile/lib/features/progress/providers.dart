import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Weekly activity for the signed-in user (GET /api/progress/me/activity).
final activityProvider = FutureProvider<ActivityData>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getActivity(days: 7);
});
