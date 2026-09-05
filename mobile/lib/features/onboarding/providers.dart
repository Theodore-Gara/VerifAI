import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/onboarding/data/track_repository.dart';
import 'package:verifai/shared/models.dart';

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return MockTrackRepository(apiClient: apiClient, secureStorage: secureStorage);
});

final tracksProvider = FutureProvider<List<IndustryTrack>>((ref) async {
  final repository = ref.watch(trackRepositoryProvider);
  return await repository.getTracks();
});

final selectedTrackProvider = StateProvider<int?>((ref) => null);

final selectTrackProvider = FutureProvider.family<void, int>((ref, trackId) async {
  final repository = ref.watch(trackRepositoryProvider);
  await repository.selectTrack(trackId);
  ref.read(selectedTrackProvider.notifier).state = trackId;
});