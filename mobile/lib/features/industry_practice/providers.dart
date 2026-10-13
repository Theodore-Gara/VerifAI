import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

final industryCasesProvider =
    FutureProvider<List<IndustryCase>>((ref) => ref.watch(apiClientProvider).getIndustryCases());

final industryCaseProvider = FutureProvider.family<IndustryCase, int>(
    (ref, id) => ref.watch(apiClientProvider).getIndustryCase(id));
