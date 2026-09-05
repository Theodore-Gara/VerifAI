import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/shared/models.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboard();
  Future<void> refreshDashboard();
}

class MockDashboardRepository implements DashboardRepository {
  final ApiClient _apiClient;

  MockDashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<DashboardData> getDashboard() async {
    return await _apiClient.getDashboard();
  }

  @override
  Future<void> refreshDashboard() async {
    // In mock, just refetch
    await _apiClient.getDashboard();
  }
}