import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

final historyProvider = FutureProvider<List<HistoryEntry>>(
    (ref) => ref.watch(apiClientProvider).getHistory());
