import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Stage-based readiness roadmap for the learner's active industry.
final roadmapProvider = FutureProvider<RoadmapData>(
    (ref) => ref.watch(apiClientProvider).getRoadmap());
