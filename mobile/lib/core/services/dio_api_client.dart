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
  Future<void> ping() async {
    await _dio.get<Map<String, dynamic>>(
      'health',
      // The Render free tier can take ~50s to wake after being idle, far over
      // the shared 10s timeout, so gives this request its own generous window.
      options: Options(
        connectTimeout: const Duration(seconds: 65),
        receiveTimeout: const Duration(seconds: 65),
      ),
    );
  }

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
    final auth = Options(headers: _authHeaders(token));
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>('users/me', options: auth),
      _dio.get<Map<String, dynamic>>('progress/me', options: auth),
      _dio.get<Map<String, dynamic>>('tasks/next',
          queryParameters: {'feature': 'verification', 'difficulty': 'easy'},
          options: auth),
      _dio.get<Map<String, dynamic>>('tasks/next',
          queryParameters: {'feature': 'verification', 'difficulty': 'medium'},
          options: auth),
      _dio.get<Map<String, dynamic>>('tasks/next',
          queryParameters: {'feature': 'verification', 'difficulty': 'hard'},
          options: auth),
    ]);

    final profile =
        responses[0].data?['user'] as Map<String, dynamic>? ?? const {};
    final progress =
        responses[1].data?['progress'] as Map<String, dynamic>? ?? const {};
    final skillScores = progress['skill_scores'] as List<dynamic>? ?? const [];

    // One card per difficulty; a track may not have content for every band.
    final tasks = <DailyTask>[];
    for (final response in responses.skip(2)) {
      final task = response.data?['task'] as Map<String, dynamic>?;
      if (task == null) continue;
      tasks.add(DailyTask.fromJson({
        ...task,
        'trackName': profile['industry_track_name'],
        'trackId': task['track_id'],
      }));
    }

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
      tier: progress['tier'] as String?,
      dailyTask: tasks.isEmpty ? null : tasks.first,
      tasks: tasks,
    );
  }

  @override
  Future<DailyTask?> getNextTask({String? feature, String? difficulty}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'tasks/next',
      queryParameters: {
        if (feature != null) 'feature': feature,
        if (difficulty != null) 'difficulty': difficulty,
      },
      options: Options(headers: _authHeaders(token)),
    );
    final task = response.data?['task'] as Map<String, dynamic>?;
    if (task == null) return null;
    return DailyTask.fromJson(task);
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'achievements/me',
      options: Options(headers: _authHeaders(token)),
    );
    final list = response.data?['achievements'] as List<dynamic>? ?? const [];
    return list
        .map((item) =>
            Achievement.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<LeaderboardData> getLeaderboard({int? trackId, int limit = 20}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'leaderboard',
      queryParameters: {'limit': limit, if (trackId != null) 'track': trackId},
      options: Options(headers: _authHeaders(token)),
    );
    return LeaderboardData.fromJson(response.data ?? const {});
  }

  @override
  Future<ActivityData> getActivity({int days = 7}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'progress/me/activity',
      queryParameters: {'days': days},
      options: Options(headers: _authHeaders(token)),
    );
    return ActivityData.fromJson(response.data ?? const {});
  }

  @override
  Future<List<Milestone>> getMilestones({int? trackId}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'achievements/milestones',
      queryParameters: {if (trackId != null) 'track': trackId},
      options: Options(headers: _authHeaders(token)),
    );
    final list = response.data?['milestones'] as List<dynamic>? ?? const [];
    return list
        .map((e) => Milestone.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<InterviewQuestion>> getInterviewQuestions() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'interview/questions',
      options: Options(headers: _authHeaders(token)),
    );
    final list = response.data?['questions'] as List<dynamic>? ?? const [];
    return list
        .map((e) =>
            InterviewQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> markInterviewPracticed(int questionId) async {
    final token = await _idToken();
    await _dio.post<Map<String, dynamic>>(
      'interview/questions/$questionId/practice',
      options: Options(headers: _authHeaders(token)),
    );
  }

  @override
  Future<TaskSubmissionResponse> submitTask(
      TaskSubmissionRequest request) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'tasks/${request.taskId}/attempt',
      data: request.toJson(),
      options: Options(headers: _authHeaders(token)),
    );
    final result =
        response.data?['result'] as Map<String, dynamic>? ?? const {};
    final newlyEarned =
        response.data?['newly_earned_achievements'] as List<dynamic>? ??
            const [];
    return TaskSubmissionResponse(
      score: _int(result['score']),
      passed: result['passed'] as bool? ?? false,
      feedback: result['feedback'] as String? ?? '',
      xpEarned: _int(result['xp_earned']),
      correctAnswer: result['expected_answer'] as String?,
      matchedKeywords: _stringList(result['matched_keywords']),
      missedKeywords: _stringList(result['missed_keywords']),
      newlyEarnedAchievements: newlyEarned
          .map((item) =>
              Achievement.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  @override
  Future<String> sendAssistantMessage({
    required int taskId,
    required List<AssistantMessage> messages,
  }) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'assistant/chat',
      data: {
        'task_id': taskId,
        'messages': messages.map((message) => message.toJson()).toList(),
      },
      options: Options(headers: _authHeaders(token)),
    );
    final reply = response.data?['reply'];
    if (reply is! String || reply.isEmpty) {
      throw const FormatException('The assistant returned an empty reply.');
    }
    return reply;
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

  List<String> _stringList(dynamic value) =>
      (value as List<dynamic>? ?? const []).map((e) => '$e').toList();
}
