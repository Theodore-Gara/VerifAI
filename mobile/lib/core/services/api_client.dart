import 'package:verifai/shared/models.dart';

abstract class ApiClient {
  Future<List<IndustryTrack>> getTracks();
  Future<AuthSyncResponse> syncUser(User user);
  Future<DashboardData> getDashboard();
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
  final String feedback;
  final int xpEarned;

  TaskSubmissionResponse({
    required this.score,
    required this.feedback,
    required this.xpEarned,
  });
}