import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'api_client.dart';
import '../../shared/models.dart';

class DioApiClient implements ApiClient {
  final Dio _dio;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  DioApiClient({
    required Dio dio,
    firebase_auth.FirebaseAuth? firebaseAuth,
  })  : _dio = dio,
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<List<IndustryTrack>> getTracks() async {
    final response = await _dio.get<Map<String, dynamic>>('tracks');
    final tracks = response.data?['tracks'] as List<dynamic>? ?? const [];
    return tracks
        .map((track) =>
            IndustryTrack.fromJson(Map<String, dynamic>.from(track as Map)))
        .toList();
  }

  @override
  Future<AuthSyncResponse> syncUser(User user) async {
    final token = await _idToken();
    await _dio.post<Map<String, dynamic>>(
      'auth/sync',
      options: Options(headers: _authHeaders(token)),
    );
    final profileResponse = await _dio.get<Map<String, dynamic>>(
      'users/me',
      options: Options(headers: _authHeaders(token)),
    );
    final syncedUser = _parseUser(profileResponse.data?['user']);
    return AuthSyncResponse(user: syncedUser, token: token);
  }

  @override
  Future<void> updateProfile(int trackId) async {
    final token = await _idToken();
    await _dio.put<void>(
      'users/profile',
      data: {'industry_track_id': trackId},
      options: Options(headers: _authHeaders(token)),
    );
  }

  @override
  Future<DashboardData> getDashboard() async {
    final token = await _idToken();
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>('users/me',
          options: Options(headers: _authHeaders(token))),
      _dio.get<Map<String, dynamic>>('progress/me',
          options: Options(headers: _authHeaders(token))),
      _dio.get<Map<String, dynamic>>('tasks/next',
          options: Options(headers: _authHeaders(token))),
    ]);

    final profile =
        responses[0].data?['user'] as Map<String, dynamic>? ?? const {};
    final progress =
        responses[1].data?['progress'] as Map<String, dynamic>? ?? const {};
    final task = responses[2].data?['task'] as Map<String, dynamic>?;
    final skillScores = progress['skill_scores'] as List<dynamic>? ?? const [];

    return DashboardData(
      overallScore: _int(progress['readiness_score']),
      dimensionScores: {
        for (final item in skillScores)
          (item as Map<String, dynamic>)['dimension'] as String:
              _int(item['score']),
      },
      streakDays: _int(progress['streak']),
      currentXp: _int(progress['xp']),
      level: _int(progress['level'], fallback: 1),
      completedTasks: _int(progress['completed_tasks']),
      dailyTask: task == null
          ? null
          : DailyTask.fromJson({
              ...task,
              'trackName': profile['industry_track_name'],
              'trackId': task['track_id'],
            }),
    );
  }

  @override
  Future<TaskSubmissionResponse> submitTask(
      TaskSubmissionRequest request) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'tasks/${request.taskId}/attempt',
      data: {
        'answer': request.answer,
        if (request.explanation != null) 'explanation': request.explanation,
      },
      options: Options(headers: _authHeaders(token)),
    );
    final result =
        response.data?['result'] as Map<String, dynamic>? ?? const {};
    return TaskSubmissionResponse(
      score: _int(result['score']),
      feedback: result['feedback'] as String? ?? '',
      xpEarned: _int(result['xp_earned']),
    );
  }

  Future<String> _idToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Sign in with Google before connecting to the backend.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase did not return an ID token.');
    }
    return token;
  }

  Map<String, String> _authHeaders(String token) =>
      {'Authorization': 'Bearer $token'};

  User _parseUser(dynamic value) {
    final json = Map<String, dynamic>.from(value as Map);
    return User(
      id: json['id'].toString(),
      email: json['email'] as String? ?? '',
      name: json['display_name'] as String?,
      trackId: json['industry_track_id']?.toString(),
      trackName: json['industry_track_name'] as String?,
      hasCompletedOnboarding: json['industry_track_id'] != null,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  int _int(dynamic value, {int fallback = 0}) =>
      int.tryParse('$value') ?? fallback;
}
