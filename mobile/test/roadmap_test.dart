import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/track/presentation/track_roadmap_screen.dart';
import 'package:verifai/shared/models.dart';

import 'support/mock_api_client.dart';

void main() {
  test('roadmap JSON parses stages and milestone progress', () {
    final roadmap = RoadmapData.fromJson({
      'track': {'id': 1, 'name': 'Finance'},
      'summary': {
        'current_stage': 2,
        'stages_completed': 1,
        'milestones_completed': 2,
        'milestones_total': 4,
        'percent': 50,
        'readiness_score': 61,
        'tier': 'Developing',
      },
      'stages': [
        {
          'code': 'foundation',
          'title': 'Foundation',
          'outcome': 'Get set up.',
          'order': 1,
          'status': 'complete',
          'milestones': [
            {
              'code': 'tour',
              'title': 'Take the tour',
              'status': 'complete',
              'current': 1,
              'target': 1,
              'unit': 'tour',
            },
          ],
        },
      ],
      'next_action': {
        'stage': 'evidence',
        'milestone': 'first-task',
        'label': 'Pass your first task',
        'route': '/practice',
      },
    });

    expect(roadmap.trackName, 'Finance');
    expect(roadmap.summary.percent, 50);
    expect(roadmap.stages.single.complete, isTrue);
    expect(roadmap.stages.single.milestones.single.progress, 1);
    expect(roadmap.nextAction?.route, '/practice');
  });

  testWidgets('roadmap renders the stages from the API', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const MaterialApp(home: TrackRoadmapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Foundation'), findsOneWidget);
    expect(find.text('Take the tour'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
  });
}
