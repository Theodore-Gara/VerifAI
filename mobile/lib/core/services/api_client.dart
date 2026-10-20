import 'package:verifai/shared/models.dart';

abstract class ApiClient {
  Future<void> ping();
  Future<List<IndustryTrack>> getTracks();
  Future<AuthSyncResponse> syncUser(User user);
  Future<void> updateProfile(int trackId);
  Future<void> deleteAccount();

  /// Who the signed-in user is on the staff side (GET /api/auth/me).
  Future<AdminIdentity> getMe();
  Future<DashboardData> getDashboard();
  Future<DailyTask?> getNextTask({String? feature, String? difficulty});
  Future<List<Achievement>> getAchievements();
  Future<LeaderboardData> getLeaderboard({int? trackId, int limit = 20});
  Future<ActivityData> getActivity({int days = 7});
  Future<List<Milestone>> getMilestones({int? trackId});
  Future<List<InterviewQuestion>> getInterviewQuestions();
  Future<void> markInterviewPracticed(int questionId);
  Future<TaskSubmissionResponse> submitTask(TaskSubmissionRequest request);
  Future<String> sendAssistantMessage({
    required int taskId,
    required List<AssistantMessage> messages,
  });
  Future<AssistantSessionDetail> getAssistantSession(int taskId);

  // --- Verification Studio ---
  Future<VerificationResult> analyzeVerification({
    required String kind,
    String? context,
    String? documentName,
    List<VerificationSourceInput> sources = const [],
    bool webSearch = true,
  });
  Future<List<VerificationResult>> getVerificationAnalyses({int limit = 20});

  // --- Vera assistant ---
  Future<VeraChatResult> sendVeraMessage({
    int? sessionId,
    required List<AssistantMessage> messages,
    String context = 'assistant',
    bool webSearch = false,
  });
  Stream<String> streamVeraMessage({
    int? sessionId,
    required List<AssistantMessage> messages,
    String context = 'assistant',
    bool webSearch = false,
    void Function(int sessionId)? onSessionId,
  });
  Future<List<VeraSession>> getVeraSessions();
  Future<VeraSessionDetail> getVeraSession(int id);
  Future<List<VeraMemory>> getVeraMemory();
  Future<void> addVeraMemory({required String kind, required String content});
  Future<void> deleteVeraMemory(int id);
  Future<List<VeraTip>> getVeraTips();

  // --- AI Lab ---
  Future<List<LabLesson>> getLabLessons();
  Future<LabLessonDetail> getLabLesson(String code);
  Future<LabLesson?> getNextLesson({bool includeSeen = true});
  Future<LabProgress> recordLessonProgress(
    String code, {
    required int sectionsCompleted,
    required int activitiesCompleted,
  });
  Future<LabActivityResult> submitActivity(
    int activityId, {
    required dynamic response,
    bool practice = false,
  });
  Future<List<LabAssessment>> getLabAssessments();
  Future<LabAssessmentPaper> getAssessmentPaper(String code);
  Future<LabAssessmentStart> startAssessment(String code);
  Future<LabAssessmentResult> submitAssessment(
    String code, {
    required int attemptId,
    required Map<int, dynamic> answers,
  });
  Future<LabAssessmentAnalysis> getAssessmentAnalysis(String code, int attemptId);

  // --- Industry Practice ---
  Future<List<IndustryCase>> getIndustryCases();
  Future<IndustryCase> getIndustryCase(int id);
  Future<void> markIndustryCaseRead(int id);

  // --- Rewards ---
  Future<RewardsData> getRewards();
  Future<RewardRedemptionResult> redeemReward(String code);
  Future<TokenHistory> getTokenHistory({int limit = 20});

  // --- History ---
  /// A page of the unified timeline. A short page means there is no more.
  Future<List<HistoryEntry>> getHistory({
    int limit = 30,
    int offset = 0,
    String? type,
    String? query,
  });

  /// One attempt by id, so feedback survives a restart or a deep link.
  Future<AttemptFeedback> getAttemptFeedback(int attemptId);

  // --- Wellness ---
  Future<List<MoodCheckin>> getMoodCheckins({int limit = 30});
  Future<void> saveMoodCheckin(String mood, {String? date, String? note});
  Future<List<JournalEntry>> getJournalEntries({int limit = 30});
  Future<void> saveJournalEntry(String content, {String? date});
  Future<void> deleteJournalEntry(String date);
  Future<void> restoreJournalEntry(String date);
  Future<WellnessWeek> getWellnessWeek({int days = 7});
  Future<void> logWellnessActivity(String activity);
}

class AssistantMessage {
  final String role;
  final String content;

  const AssistantMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AuthSyncResponse {
  final User user;
  final String token;

  AuthSyncResponse({required this.user, required this.token});
}

class TaskSubmissionRequest {
  final int taskId;
  final String? answer;
  final int? answerOptionId;
  final int? decisionOptionId;
  final int? reasonOptionId;
  final String? rationale;
  final String? explanation;
  final List<int>? selectedLines;
  final String? fix;
  final String? reason;
  final bool practice;

  TaskSubmissionRequest({
    required this.taskId,
    this.answer,
    this.answerOptionId,
    this.decisionOptionId,
    this.reasonOptionId,
    this.rationale,
    this.explanation,
    this.selectedLines,
    this.fix,
    this.reason,
    this.practice = false,
  });

  Map<String, dynamic> toJson() => {
        if (answer != null) 'answer': answer,
        if (answerOptionId != null) 'answer_option_id': answerOptionId,
        if (decisionOptionId != null) 'decision_option_id': decisionOptionId,
        if (reasonOptionId != null) 'reason_option_id': reasonOptionId,
        if (rationale != null) 'rationale': rationale,
        if (explanation != null) 'explanation': explanation,
        if (selectedLines != null) 'selected_lines': selectedLines,
        if (fix != null) 'fix': fix,
        if (reason != null) 'reason': reason,
        if (practice) 'practice': true,
      };
}

class TaskSubmissionResponse {
  final int score;
  final bool passed;
  final String feedback;
  final int xpEarned;
  final String? correctAnswer;
  final List<String> matchedKeywords;
  final List<String> missedKeywords;
  final List<Achievement> newlyEarnedAchievements;

  TaskSubmissionResponse({
    required this.score,
    this.passed = false,
    required this.feedback,
    required this.xpEarned,
    this.correctAnswer,
    this.matchedKeywords = const [],
    this.missedKeywords = const [],
    this.newlyEarnedAchievements = const [],
  });
}

class AssistantSessionDetail {
  final AssistantSession? session;
  final List<AssistantMessageModel> messages;

  const AssistantSessionDetail({required this.session, required this.messages});

  factory AssistantSessionDetail.fromJson(Map<String, dynamic> json) => AssistantSessionDetail(
        session: json['session'] != null
            ? AssistantSession.fromJson(Map<String, dynamic>.from(json['session'] as Map))
            : null,
        messages: ((json['messages'] as List<dynamic>?) ?? const [])
            .map((e) => AssistantMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
