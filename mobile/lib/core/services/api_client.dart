import 'package:verifai/shared/models.dart';

abstract class ApiClient {
  Future<List<IndustryTrack>> getTracks();
  Future<AuthSyncResponse> syncUser(User user);
  Future<void> updateProfile(int trackId);
  Future<DashboardData> getDashboard();
  Future<List<Achievement>> getAchievements();
  Future<TaskSubmissionResponse> submitTask(TaskSubmissionRequest request);
}

class AuthSyncResponse {
  final User user;
  final String token;

  AuthSyncResponse({required this.user, required this.token});
}

class TaskSubmissionRequest {
  final int taskId;
  final String answer;
  final String? explanation;

  TaskSubmissionRequest({
    required this.taskId,
    required this.answer,
    this.explanation,
  });
}

class TaskSubmissionResponse {
  final int score;
  final bool passed;
  final String feedback;
  final int xpEarned;
  final List<String> matchedKeywords;
  final List<String> missedKeywords;
  final List<Achievement> newlyEarnedAchievements;

  TaskSubmissionResponse({
    required this.score,
    this.passed = false,
    required this.feedback,
    required this.xpEarned,
    this.matchedKeywords = const [],
    this.missedKeywords = const [],
    this.newlyEarnedAchievements = const [],
  });
}
