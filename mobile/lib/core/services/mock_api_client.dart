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
  Future<DashboardData> getDashboard() async {
    await _delay();
    final dailyTask = _dailyTasks[_random.nextInt(_dailyTasks.length)];
    return DashboardData(
      overallScore: 68,
      dimensionScores: Map.from(_dimensionScores),
      streakDays: 7,
      dailyTask: dailyTask,
    );
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    await _delay();
    return const [];
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
      matchedKeywords: const [
        'verify source records',
        'correct the missed payment',
      ],
      missedKeywords: const [],
    );
  }
}
