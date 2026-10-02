import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/dashboard/data/dashboard_repository.dart';
import 'package:verifai/shared/models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MockDashboardRepository(apiClient: apiClient);
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getDashboard();
});

final refreshDashboardProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  await repository.refreshDashboard();
  ref.invalidate(dashboardProvider);
});