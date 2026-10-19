import 'dart:convert';

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
  Future<void> deleteAccount() async {
    final token = await _idToken();
    await _dio.delete<void>('users/me', options: Options(headers: _authHeaders(token)));
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

  @override
  Future<AssistantSessionDetail> getAssistantSession(int taskId) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'assistant/sessions/$taskId',
      options: Options(headers: _authHeaders(token)),
    );
    return AssistantSessionDetail.fromJson(response.data ?? const {});
  }

  // --- Verification Studio ---
  @override
  Future<VerificationResult> analyzeVerification({
    required String kind,
    String? context,
    String? documentName,
    List<VerificationSourceInput> sources = const [],
    bool webSearch = true,
  }) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'verification/analyze',
      data: {
        'kind': kind,
        if (context != null && context.isNotEmpty) 'context': context,
        if (documentName != null) 'document_name': documentName,
        'sources': sources.map((s) => s.toJson()).toList(),
        'web_search': webSearch,
      },
      options: Options(
        headers: _authHeaders(token),
        // Large documents + live analysis: give the request room.
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return VerificationResult.fromJson(response.data ?? const {});
  }

  @override
  Future<List<VerificationResult>> getVerificationAnalyses({int limit = 20}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>(
      'verification/analyses',
      queryParameters: {'limit': limit},
      options: Options(headers: _authHeaders(token)),
    );
    final list = response.data?['analyses'] as List<dynamic>? ?? const [];
    return list
        .map((e) => VerificationResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // --- Vera assistant ---
  @override
  Future<VeraChatResult> sendVeraMessage({
    int? sessionId,
    required List<AssistantMessage> messages,
    String context = 'assistant',
    bool webSearch = false,
  }) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'vera/chat',
      data: {
        if (sessionId != null) 'session_id': sessionId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'context': context,
        if (webSearch) 'web_search': true,
      },
      options: Options(
        headers: _authHeaders(token),
        connectTimeout: const Duration(seconds: 65),
        sendTimeout: const Duration(seconds: 65),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    final data = response.data ?? const {};
    return VeraChatResult(
      sessionId: int.tryParse('${data['session_id']}') ?? 0,
      reply: data['reply'] as String? ?? '',
      sources: (data['sources'] as List<dynamic>? ?? const [])
          .map((e) => VeraSource.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      webSearched: data['web_searched'] as bool? ?? false,
    );
  }

  @override
  Stream<String> streamVeraMessage({
    int? sessionId,
    required List<AssistantMessage> messages,
    String context = 'assistant',
    bool webSearch = false,
    void Function(int sessionId)? onSessionId,
  }) async* {
    final token = await _idToken();
    final body = {
      if (sessionId != null) 'session_id': sessionId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'context': context,
      if (webSearch) 'web_search': true,
      'stream': true,
    };
    // AI replies can be slow, and the Render free tier sleeps when idle (the
    // first request after a quiet spell can take ~50s to wake). Give the call a
    // generous window instead of the shared 10s base timeout, and retry once if
    // the connection never produced a response.
    Options options() => Options(
          headers: _authHeaders(token),
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 65),
          sendTimeout: const Duration(seconds: 65),
          receiveTimeout: const Duration(seconds: 120),
        );
    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>('vera/chat',
          data: body, queryParameters: {'stream': '1'}, options: options());
    } on DioException catch (e) {
      if (e.response != null) rethrow;
      response = await _dio.post<ResponseBody>('vera/chat',
          data: body, queryParameters: {'stream': '1'}, options: options());
    }

    var buffer = '';
    await for (final chunk in response.data!.stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      var index = buffer.indexOf('\n');
      while (index >= 0) {
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);
        index = buffer.indexOf('\n');
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data == '[DONE]') return;
        Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          continue; // ignore partial/unparseable frames
        }
        final sid = json['session_id'];
        if (sid is int) onSessionId?.call(sid);
        final error = json['error'];
        if (error is String && error.isNotEmpty) throw Exception(error);
        final delta = json['delta'];
        if (delta is String && delta.isNotEmpty) yield delta;
      }
    }
  }

  @override
  Future<List<VeraSession>> getVeraSessions() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('vera/sessions',
        options: Options(headers: _authHeaders(token)));
    final list = response.data?['sessions'] as List<dynamic>? ?? const [];
    return list.map((e) => VeraSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<VeraSessionDetail> getVeraSession(int id) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('vera/sessions/$id',
        options: Options(headers: _authHeaders(token)));
    return VeraSessionDetail.fromJson(response.data ?? const {});
  }

  @override
  Future<List<VeraMemory>> getVeraMemory() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('vera/memory',
        options: Options(headers: _authHeaders(token)));
    final list = response.data?['memories'] as List<dynamic>? ?? const [];
    return list.map((e) => VeraMemory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<void> addVeraMemory({required String kind, required String content}) async {
    final token = await _idToken();
    await _dio.post<Map<String, dynamic>>('vera/memory',
        data: {'kind': kind, 'content': content},
        options: Options(headers: _authHeaders(token)));
  }

  @override
  Future<void> deleteVeraMemory(int id) async {
    final token = await _idToken();
    await _dio.delete<Map<String, dynamic>>('vera/memory/$id',
        options: Options(headers: _authHeaders(token)));
  }

  @override
  Future<List<VeraTip>> getVeraTips() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('vera/tips',
        options: Options(headers: _authHeaders(token)));
    final list = response.data?['tips'] as List<dynamic>? ?? const [];
    return list.map((e) => VeraTip.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // --- AI Lab ---
  @override
  Future<List<LabLesson>> getLabLessons() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('lab/lessons',
        options: Options(headers: _authHeaders(token)));
    final list = response.data?['lessons'] as List<dynamic>? ?? const [];
    return list.map((e) => LabLesson.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<LabLessonDetail> getLabLesson(String code) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('lab/lessons/$code',
        options: Options(headers: _authHeaders(token)));
    return LabLessonDetail.fromJson(response.data ?? const {});
  }

  @override
  Future<LabLesson?> getNextLesson({bool includeSeen = true}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('lab/lessons/next',
        queryParameters: {'include_seen': includeSeen},
        options: Options(headers: _authHeaders(token)));
    final lesson = response.data?['lesson'] as Map<String, dynamic>?;
    return lesson == null ? null : LabLesson.fromJson(lesson);
  }

  @override
  Future<LabProgress> recordLessonProgress(
    String code, {
    required int sectionsCompleted,
    required int activitiesCompleted,
  }) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'lab/lessons/$code/progress',
      data: {'sections_completed': sectionsCompleted, 'activities_completed': activitiesCompleted},
      options: Options(headers: _authHeaders(token)),
    );
    return LabProgress.fromJson(
        (response.data?['progress'] as Map?)?.cast<String, dynamic>() ?? const {});
  }

  @override
  Future<LabActivityResult> submitActivity(
    int activityId, {
    required dynamic response,
    bool practice = false,
  }) async {
    final token = await _idToken();
    final result = await _dio.post<Map<String, dynamic>>(
      'lab/activities/$activityId/attempt',
      data: {'response': response, if (practice) 'practice': true},
      options: Options(headers: _authHeaders(token), receiveTimeout: const Duration(seconds: 30)),
    );
    return LabActivityResult.fromJson(result.data ?? const {});
  }

  @override
  Future<List<LabAssessment>> getLabAssessments() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('lab/assessments',
        options: Options(headers: _authHeaders(token)));
    final list = response.data?['assessments'] as List<dynamic>? ?? const [];
    return list.map((e) => LabAssessment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<LabAssessmentPaper> getAssessmentPaper(String code) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('lab/assessments/$code',
        options: Options(headers: _authHeaders(token), receiveTimeout: const Duration(seconds: 30)));
    return LabAssessmentPaper.fromJson(response.data ?? const {});
  }

  @override
  Future<LabAssessmentStart> startAssessment(String code) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>('lab/assessments/$code/start',
        options: Options(headers: _authHeaders(token), receiveTimeout: const Duration(seconds: 30)));
    return LabAssessmentStart.fromJson(response.data ?? const {});
  }

  @override
  Future<LabAssessmentResult> submitAssessment(
    String code, {
    required int attemptId,
    required Map<int, dynamic> answers,
  }) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'lab/assessments/$code/submit',
      data: {
        'attempt_id': attemptId,
        'answers': {for (final e in answers.entries) '${e.key}': e.value},
      },
      options: Options(headers: _authHeaders(token), receiveTimeout: const Duration(seconds: 60)),
    );
    return LabAssessmentResult.fromJson(response.data ?? const {});
  }

  @override
  Future<LabAssessmentAnalysis> getAssessmentAnalysis(String code, int attemptId) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>(
      'lab/assessments/$code/attempts/$attemptId/analysis',
      options: Options(headers: _authHeaders(token), receiveTimeout: const Duration(seconds: 90)),
    );
    return LabAssessmentAnalysis.fromJson(response.data ?? const {});
  }

  // --- Industry Practice ---
  @override
  Future<List<IndustryCase>> getIndustryCases() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('industry-practice/cases',
        options: Options(headers: _authHeaders(token)));
    final list = response.data?['cases'] as List<dynamic>? ?? const [];
    return list.map((e) => IndustryCase.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<IndustryCase> getIndustryCase(int id) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('industry-practice/cases/$id',
        options: Options(headers: _authHeaders(token)));
    return IndustryCase.fromJson(response.data ?? const {});
  }

  @override
  Future<void> markIndustryCaseRead(int id) async {
    final token = await _idToken();
    await _dio.post<Map<String, dynamic>>('industry-practice/cases/$id/read',
        options: Options(headers: _authHeaders(token)));
  }

  // --- Rewards ---
  @override
  Future<RewardsData> getRewards() async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('rewards',
        options: Options(headers: _authHeaders(token)));
    return RewardsData.fromJson(response.data ?? const {});
  }

  @override
  Future<RewardRedemptionResult> redeemReward(String code) async {
    final token = await _idToken();
    final response = await _dio.post<Map<String, dynamic>>('rewards/$code/redeem',
        options: Options(headers: _authHeaders(token), receiveTimeout: const Duration(seconds: 30)));
    return RewardRedemptionResult.fromJson(response.data ?? const {});
  }

  @override
  Future<TokenHistory> getTokenHistory({int limit = 20}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('rewards/tokens',
        queryParameters: {'limit': limit}, options: Options(headers: _authHeaders(token)));
    return TokenHistory.fromJson(response.data ?? const {});
  }

  // --- History ---
  @override
  Future<List<HistoryEntry>> getHistory({int limit = 30}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('history',
        queryParameters: {'limit': limit}, options: Options(headers: _authHeaders(token)));
    final list = response.data?['entries'] as List<dynamic>? ?? const [];
    return list.map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // --- Wellness ---
  @override
  Future<List<MoodCheckin>> getMoodCheckins({int limit = 30}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('wellness/mood',
        queryParameters: {'limit': limit}, options: Options(headers: _authHeaders(token)));
    final list = response.data?['checkins'] as List<dynamic>? ?? const [];
    return list.map((e) => MoodCheckin.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<void> saveMoodCheckin(String mood, {String? date}) async {
    final token = await _idToken();
    await _dio.put<Map<String, dynamic>>(
      'wellness/mood',
      data: {'mood': mood, if (date != null) 'date': date},
      options: Options(headers: _authHeaders(token)),
    );
  }

  @override
  Future<List<JournalEntry>> getJournalEntries({int limit = 30}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('wellness/journal',
        queryParameters: {'limit': limit}, options: Options(headers: _authHeaders(token)));
    final list = response.data?['entries'] as List<dynamic>? ?? const [];
    return list.map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<void> saveJournalEntry(String content, {String? date}) async {
    final token = await _idToken();
    await _dio.put<Map<String, dynamic>>(
      'wellness/journal',
      data: {'content': content, if (date != null) 'date': date},
      options: Options(headers: _authHeaders(token)),
    );
  }

  @override
  Future<WellnessWeek> getWellnessWeek({int days = 7}) async {
    final token = await _idToken();
    final response = await _dio.get<Map<String, dynamic>>('wellness/activities',
        queryParameters: {'days': days}, options: Options(headers: _authHeaders(token)));
    return WellnessWeek.fromJson(response.data ?? const {});
  }

  @override
  Future<void> logWellnessActivity(String activity) async {
    final token = await _idToken();
    await _dio.post<Map<String, dynamic>>(
      'wellness/activities',
      data: {'activity': activity},
      options: Options(headers: _authHeaders(token)),
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

  List<String> _stringList(dynamic value) =>
      (value as List<dynamic>? ?? const []).map((e) => '$e').toList();
}
