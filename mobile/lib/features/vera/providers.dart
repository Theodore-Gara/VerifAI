import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

final veraSessionsProvider = FutureProvider<List<VeraSession>>(
    (ref) => ref.watch(apiClientProvider).getVeraSessions());

final veraSessionProvider = FutureProvider.family<VeraSessionDetail, int>(
    (ref, id) => ref.watch(apiClientProvider).getVeraSession(id));

final veraMemoryProvider = FutureProvider<List<VeraMemory>>(
    (ref) => ref.watch(apiClientProvider).getVeraMemory());

final veraTipsProvider = FutureProvider<List<VeraTip>>(
    (ref) => ref.watch(apiClientProvider).getVeraTips());
