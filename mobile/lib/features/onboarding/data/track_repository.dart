import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/core/services/secure_storage_service.dart';
import 'package:verifai/shared/models.dart';

abstract class TrackRepository {
  Future<List<IndustryTrack>> getTracks();
  Future<void> selectTrack(int trackId);
}

class MockTrackRepository implements TrackRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  MockTrackRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  @override
  Future<List<IndustryTrack>> getTracks() async {
    return await _apiClient.getTracks();
  }

  @override
  Future<void> selectTrack(int trackId) async {
    // In mock, we just save to secure storage
    final tracks = await _apiClient.getTracks();
    final track = tracks.firstWhere((t) => t.id == trackId);
    await _secureStorage.updateTrack(trackId.toString(), track.name);
  }
}