import 'dart:async';
import 'dart:math';

import 'package:verifai/shared/models.dart';
import 'package:verifai/core/services/api_client.dart';

class MockApiClient implements ApiClient {
  final Random _random = Random();

  // Simulated delay
  Future<void> _delay() async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));
  }

  // In-memory data
  static const List<IndustryTrack> _tracks = [
    IndustryTrack(
        id: 1,
        name: 'Finance',
        description: 'Financial services and banking scenarios'),
    IndustryTrack(
        id: 2,
        name: 'Legal',
        description: 'Legal research and compliance scenarios'),
    IndustryTrack(
        id: 3,
        name: 'IT / Software',
        description: 'Software development and IT operations scenarios'),
    IndustryTrack(
        id: 4,
        name: 'Business Consulting',
        description: 'Management consulting and strategy scenarios'),
  ];

  static const List<DailyTask> _dailyTasks = [
    DailyTask(
      id: 1,
      title: 'Review AI-generated financial forecast',
      scenario:
          'An AI model has predicted Q3 revenue with 15% growth. The model used last year\'s data but didn\'t account for the new market entrant.',
      dimension: 'verification',
      embeddedFlaw: 'The forecast ignores the new market entrant.',
      options: [
        TaskOption(
            id: 1, label: 'Verify the source data and recalculate growth.'),
        TaskOption(id: 2, label: 'Approve the forecast as presented.'),
        TaskOption(id: 3, label: 'Reject the forecast without review.'),
        TaskOption(id: 4, label: 'Request supporting citations first.'),
      ],
      trackName: 'Finance',
      difficulty: 'medium',
      trackId: 1,
    ),
    DailyTask(
      id: 2,
      title: 'Assess legal contract clause suggested by AI',
      scenario:
          'AI suggested a force majeure clause that excludes pandemics. The jurisdiction recently ruled pandemics are covered.',
      dimension: 'judgement',
      embeddedFlaw:
          'The suggested clause excludes pandemics despite the recent ruling.',
      options: [
        TaskOption(
            id: 5, label: 'Check the current ruling and revise the clause.'),
        TaskOption(id: 6, label: 'Use the suggested clause as written.'),
        TaskOption(id: 7, label: 'Remove every force majeure provision.'),
      ],
      trackName: 'Legal',
      difficulty: 'hard',
      trackId: 2,
    ),
    DailyTask(
      id: 3,
      title: 'Debug AI-generated code snippet',
      scenario:
          'AI wrote a recursive function without a base case. The function causes stack overflow on large inputs.',
      dimension: 'prompt_design',
      embeddedFlaw: 'The recursive function has no base case.',
      options: [
        TaskOption(id: 8, label: 'Add and test a terminating base case.'),
        TaskOption(id: 9, label: 'Increase the recursion limit.'),
        TaskOption(id: 10, label: 'Deploy without changes.'),
      ],
      trackName: 'IT / Software',
      difficulty: 'easy',
      trackId: 3,
    ),
    DailyTask(
      id: 4,
      title: 'Evaluate AI hiring recommendation',
      scenario:
          'AI recommended a candidate based on keywords but missed a 2-year employment gap that explains the skill mismatch.',
      dimension: 'risk_governance',
      embeddedFlaw: 'The recommendation overlooks relevant employment history.',
      options: [
        TaskOption(id: 11, label: 'Review the complete application fairly.'),
        TaskOption(id: 12, label: 'Accept the recommendation without review.'),
        TaskOption(
            id: 13, label: 'Reject the candidate based only on the gap.'),
      ],
      trackName: 'Business Consulting',
      difficulty: 'medium',
      trackId: 4,
    ),
  ];

  final Map<String, int> _dimensionScores = {
    'verification': 72,
    'judgement': 65,
    'prompt_design': 78,
    'risk_governance': 58,
    'human_ai_collab': 70,
  };

  @override
  Future<void> ping() async {
    await _delay();
  }

  @override
  Future<List<IndustryTrack>> getTracks() async {
    await _delay();
    return List.from(_tracks);
  }

  @override
  Future<AuthSyncResponse> syncUser(User user) async {
    await _delay();
    // Generate a mock token
    final token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    return AuthSyncResponse(user: user.copyWith(id: '1'), token: token);
  }

  @override
  Future<void> updateProfile(int trackId) async {
    // The mock repository already simulates the track fetch delay.
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<DashboardData> getDashboard() async {
    await _delay();
    final tasks = <DailyTask>[];
    for (final difficulty in const ['easy', 'medium', 'hard']) {
      final match = _dailyTasks.where((t) => t.difficulty == difficulty);
      if (match.isNotEmpty) tasks.add(match.first);
    }
    return DashboardData(
      overallScore: 68,
      dimensionScores: Map.from(_dimensionScores),
      streakDays: 7,
      tier: 'Developing',
      dailyTask: _dailyTasks[_random.nextInt(_dailyTasks.length)],
      tasks: tasks,
    );
  }

  @override
  Future<DailyTask?> getNextTask({String? feature, String? difficulty}) async {
    await _delay();
    for (final task in _dailyTasks) {
      if (feature != null && task.dimension != feature) continue;
      if (difficulty != null && task.difficulty != difficulty) continue;
      return task;
    }
    return null;
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    await _delay();
    return const [];
  }

  @override
  Future<LeaderboardData> getLeaderboard({int? trackId, int limit = 20}) async {
    await _delay();
    const me = LeaderboardEntry(
      rank: 8,
      userId: 1,
      name: 'You',
      level: 5,
      xp: 2450,
      streak: 7,
      readinessScore: 68,
      tier: 'Developing',
      isCurrentUser: true,
    );
    const others = [
      LeaderboardEntry(
          rank: 1,
          userId: 21,
          name: 'Elena Rostova',
          level: 12,
          xp: 4850,
          streak: 24,
          readinessScore: 92,
          tier: 'Advanced',
          isCurrentUser: false),
      LeaderboardEntry(
          rank: 2,
          userId: 22,
          name: 'Marcus Chen',
          level: 11,
          xp: 4210,
          streak: 18,
          readinessScore: 88,
          tier: 'Advanced',
          isCurrentUser: false),
      LeaderboardEntry(
          rank: 3,
          userId: 23,
          name: 'Sarah Jenkins',
          level: 10,
          xp: 3980,
          streak: 14,
          readinessScore: 85,
          tier: 'Advanced',
          isCurrentUser: false),
      LeaderboardEntry(
          rank: 4,
          userId: 24,
          name: 'David Kim',
          level: 9,
          xp: 3450,
          streak: 11,
          readinessScore: 78,
          tier: 'Proficient',
          isCurrentUser: false),
    ];
    return LeaderboardData(
      trackId: trackId,
      entries: [...others, me],
      me: me,
    );
  }

  @override
  Future<ActivityData> getActivity({int days = 7}) async {
    await _delay();
    final today = DateTime.now();
    final activity = List.generate(days, (index) {
      final date = today.subtract(Duration(days: days - 1 - index));
      final iso = date.toIso8601String().split('T').first;
      final xp = (index % 3 == 0) ? 0 : 30 + index * 6;
      return ActivityDay(
        date: iso,
        attempts: xp == 0 ? 0 : 1,
        xpEarned: xp,
        passed: xp == 0 ? 0 : 1,
      );
    });
    return ActivityData(
      days: days,
      streak: 7,
      lastActivityDate: activity.last.date,
      activity: activity,
    );
  }

  @override
  Future<List<Milestone>> getMilestones({int? trackId}) async {
    await _delay();
    return const [
      Milestone(
          code: 'first_task',
          name: 'First Steps',
          description: 'Complete your first task',
          target: 1,
          current: 1,
          achieved: true),
      Milestone(
          code: 'track_master',
          name: 'Track Master',
          description: 'Complete every task in the track (15)',
          target: 15,
          current: 6,
          achieved: false),
      Milestone(
          code: 'xp_250',
          name: 'Committed',
          description: 'Earn 250 XP',
          target: 250,
          current: 2450,
          achieved: true),
      Milestone(
          code: 'xp_1000',
          name: 'Dedicated',
          description: 'Earn 1000 XP',
          target: 1000,
          current: 2450,
          achieved: true),
      Milestone(
          code: 'streak_7',
          name: 'On Fire',
          description: 'Reach a 7-day streak',
          target: 7,
          current: 7,
          achieved: true),
      Milestone(
          code: 'level_5',
          name: 'Seasoned',
          description: 'Reach level 5',
          target: 5,
          current: 5,
          achieved: true),
    ];
  }

  @override
  Future<List<InterviewQuestion>> getInterviewQuestions() async {
    await _delay();
    return const [
      InterviewQuestion(
        id: 1,
        question:
            'Walk me through how you verify an AI-generated legal citation.',
        sampleAnswer:
            'I find the case myself on SAFLII or Juta using the exact citation, and read the paragraph the proposition comes from.',
        whatEmployersTest: 'A repeatable verification workflow.',
        practiced: true,
        sortOrder: 1,
      ),
      InterviewQuestion(
        id: 2,
        question: 'When would you refuse to let AI draft an affidavit?',
        sampleAnswer:
            'When the content is sensitive or sworn evidence must be the witness or client own account.',
        whatEmployersTest: 'Judgement beyond drafting accuracy.',
        practiced: false,
        sortOrder: 2,
      ),
    ];
  }

  @override
  Future<void> markInterviewPracticed(int questionId) async {
    await _delay();
  }

  @override
  Future<TaskSubmissionResponse> submitTask(
      TaskSubmissionRequest request) async {
    await _delay();
    return TaskSubmissionResponse(
      score: 85,
      passed: true,
      feedback: 'Great job! You correctly identified the missing base case.',
      xpEarned: 120,
      correctAnswer: 'Verify the source data and recalculate growth.',
      matchedKeywords: const [
        'verify source records',
        'correct the missed payment',
      ],
      missedKeywords: const [],
    );
  }

  @override
  Future<String> sendAssistantMessage({
    required int taskId,
    required List<AssistantMessage> messages,
  }) async {
    await _delay();
    return 'Start by identifying the specific claim in the scenario. What source or information would help you check it?';
  }

  @override
  Future<AssistantSessionDetail> getAssistantSession(int taskId) async {
    await _delay();
    return const AssistantSessionDetail(session: null, messages: []);
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
    await _delay();
    return VerificationResult(
      id: 1,
      kind: kind,
      documentName: documentName,
      overallStatus: 'human_review_required',
    );
  }

  @override
  Future<List<VerificationResult>> getVerificationAnalyses({int limit = 20}) async {
    await _delay();
    return const [];
  }

  // --- Vera assistant ---
  @override
  Future<VeraChatResult> sendVeraMessage({
    int? sessionId,
    required List<AssistantMessage> messages,
    String context = 'assistant',
    bool webSearch = false,
  }) async {
    await _delay();
    return VeraChatResult(sessionId: sessionId ?? 1, reply: 'Hi, I am Vera.');
  }

  @override
  Stream<String> streamVeraMessage({
    int? sessionId,
    required List<AssistantMessage> messages,
    String context = 'assistant',
    bool webSearch = false,
    void Function(int sessionId)? onSessionId,
  }) async* {
    onSessionId?.call(sessionId ?? 1);
    yield 'Hi, I am Vera.';
  }

  @override
  Future<List<VeraSession>> getVeraSessions() async {
    await _delay();
    return const [];
  }

  @override
  Future<VeraSessionDetail> getVeraSession(int id) async {
    await _delay();
    return VeraSessionDetail(
      session: VeraSession(
          id: id, context: 'assistant', startedAt: '', lastActiveAt: '', messageCount: 0),
      messages: const [],
    );
  }

  @override
  Future<List<VeraMemory>> getVeraMemory() async {
    await _delay();
    return const [];
  }

  @override
  Future<void> addVeraMemory({required String kind, required String content}) async {}

  @override
  Future<void> deleteVeraMemory(int id) async {}

  @override
  Future<List<VeraTip>> getVeraTips() async {
    await _delay();
    return const [];
  }

  // --- AI Lab ---
  @override
  Future<List<LabLesson>> getLabLessons() async {
    await _delay();
    return const [];
  }

  @override
  Future<LabLessonDetail> getLabLesson(String code) async {
    await _delay();
    return LabLessonDetail(lesson: LabLesson(id: 0, code: code, title: code, summary: ''));
  }

  @override
  Future<LabLesson?> getNextLesson({bool includeSeen = true}) async {
    await _delay();
    return null;
  }

  @override
  Future<LabProgress> recordLessonProgress(
    String code, {
    required int sectionsCompleted,
    required int activitiesCompleted,
  }) async {
    await _delay();
    return const LabProgress();
  }

  @override
  Future<LabActivityResult> submitActivity(
    int activityId, {
    required dynamic response,
    bool practice = false,
  }) async {
    await _delay();
    return const LabActivityResult(passed: true, xpEarned: 10);
  }

  @override
  Future<List<LabAssessment>> getLabAssessments() async {
    await _delay();
    return const [];
  }

  @override
  Future<LabAssessmentPaper> getAssessmentPaper(String code) async {
    await _delay();
    return LabAssessmentPaper(assessment: LabAssessment(id: 0, code: code, title: code));
  }

  @override
  Future<LabAssessmentStart> startAssessment(String code) async {
    await _delay();
    return const LabAssessmentStart(
      attemptId: 1,
      startedAt: '',
      expiresAt: '',
      timeLimitSeconds: 2400,
      passScore: 60,
      totalMarks: 25,
      attemptsRemaining: 3,
    );
  }

  @override
  Future<LabAssessmentResult> submitAssessment(
    String code, {
    required int attemptId,
    required Map<int, dynamic> answers,
  }) async {
    await _delay();
    return const LabAssessmentResult();
  }

  @override
  Future<LabAssessmentAnalysis> getAssessmentAnalysis(String code, int attemptId) async {
    await _delay();
    return const LabAssessmentAnalysis(report: 'Keep going.');
  }

  // --- Industry Practice ---
  @override
  Future<List<IndustryCase>> getIndustryCases() async {
    await _delay();
    return const [];
  }

  @override
  Future<IndustryCase> getIndustryCase(int id) async {
    await _delay();
    return IndustryCase(id: id, title: 'Case');
  }

  @override
  Future<void> markIndustryCaseRead(int id) async {}

  // --- Rewards ---
  @override
  Future<RewardsData> getRewards() async {
    await _delay();
    return const RewardsData();
  }

  @override
  Future<RewardRedemptionResult> redeemReward(String code) async {
    await _delay();
    return RewardRedemptionResult(rewardCode: code);
  }

  @override
  Future<TokenHistory> getTokenHistory({int limit = 20}) async {
    await _delay();
    return const TokenHistory();
  }

  // --- History ---
  @override
  Future<List<HistoryEntry>> getHistory({int limit = 30}) async {
    await _delay();
    return const [];
  }
}
