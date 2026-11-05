import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/onboarding/data/track_repository.dart';
import 'package:verifai/shared/models.dart';

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return MockTrackRepository(
      apiClient: apiClient, secureStorage: secureStorage);
});

final tracksProvider = FutureProvider<List<IndustryTrack>>((ref) async {
  final repository = ref.watch(trackRepositoryProvider);
  return await repository.getTracks();
});

final selectedTrackProvider = StateProvider<int?>((ref) => null);

/// Server-side tour state for the current track. Null means the call failed;
/// the UI falls back to local completion storage instead of blocking.
final tourStateProvider = FutureProvider<TutorialState?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getTourState();
  } catch (_) {
    return null;
  }
});
