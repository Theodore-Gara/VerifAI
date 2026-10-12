import 'package:verifai/shared/models.dart';

abstract class ApiClient {
  Future<void> ping();
  Future<List<IndustryTrack>> getTracks();
  Future<AuthSyncResponse> syncUser(User user);
  Future<void> updateProfile(int trackId);
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
