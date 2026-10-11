import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/shared/models/daily_task.dart';

void main() {
  test('DailyTask parses backend options and embedded flaw', () {
    final task = DailyTask.fromJson({
      'id': 42,
      'title': 'Review the forecast',
      'scenario': 'Revenue is expected to increase.',
      'dimension': 'verification',
      'format': 'choice',
      'embedded_flaw': 'The forecast omits a new market entrant.',
      'options': [
        {'id': 101, 'label': 'Check the underlying source data.'},
        {'id': 102, 'label': 'Approve the forecast.'},
      ],
    });

    expect(task.embeddedFlaw, 'The forecast omits a new market entrant.');
    expect(task.options.map((option) => option.id), [101, 102]);
    expect(task.options.first.label, 'Check the underlying source data.');
    expect(task.toJson()['options'], [
      {'id': 101, 'label': 'Check the underlying source data.'},
      {'id': 102, 'label': 'Approve the forecast.'},
    ]);
  });

  test('choice submissions use the backend answer option contract', () {
    expect(
      TaskSubmissionRequest(taskId: 42, answerOptionId: 101).toJson(),
      {'answer_option_id': 101},
    );
  });

  test('line-text submissions carry selected lines, fix, and reason', () {
    expect(
      TaskSubmissionRequest(
        taskId: 42,
        selectedLines: const [2, 5],
        fix: 'Correct the calculation.',
        reason: 'It uses the wrong comparison period.',
      ).toJson(),
      {
        'selected_lines': [2, 5],
        'fix': 'Correct the calculation.',
        'reason': 'It uses the wrong comparison period.',
      },
    );
  });

  test('practice retries are marked so the backend awards no XP', () {
    expect(
      TaskSubmissionRequest(
        taskId: 42,
        answerOptionId: 101,
        practice: true,
      ).toJson(),
      {'answer_option_id': 101, 'practice': true},
    );
  });
}
