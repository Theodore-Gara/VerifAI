import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

final moodHistoryProvider = FutureProvider<List<MoodCheckin>>(
    (ref) => ref.watch(apiClientProvider).getMoodCheckins());

final journalEntriesProvider = FutureProvider<List<JournalEntry>>(
    (ref) => ref.watch(apiClientProvider).getJournalEntries());

final wellnessWeekProvider = FutureProvider<WellnessWeek>(
    (ref) => ref.watch(apiClientProvider).getWellnessWeek());
