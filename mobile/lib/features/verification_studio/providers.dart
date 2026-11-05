import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

final verificationHistoryProvider = FutureProvider<List<VerificationResult>>(
    (ref) => ref.watch(apiClientProvider).getVerificationAnalyses());

/// Server limits for the studio. A failed call falls back to the API defaults
/// rather than blocking the form.
final verificationMetaProvider = FutureProvider<VerificationMeta>((ref) async {
  try {
    return await ref.watch(apiClientProvider).getVerificationMeta();
  } catch (_) {
    return const VerificationMeta();
  }
});
