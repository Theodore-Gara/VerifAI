import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Interview Practice bank for the signed-in user's track (Legal only for now).
final interviewQuestionsProvider =
    FutureProvider<List<InterviewQuestion>>((ref) async {
  return ref.watch(apiClientProvider).getInterviewQuestions();
});
