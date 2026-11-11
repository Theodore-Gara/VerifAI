import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

final supportHelpProvider = FutureProvider<List<SupportHelpArticle>>(
    (ref) => ref.watch(apiClientProvider).getSupportHelp());

final supportFaqsProvider = FutureProvider<List<SupportFaq>>(
    (ref) => ref.watch(apiClientProvider).getSupportFaqs());

final supportGuidesProvider = FutureProvider<List<SupportGuide>>(
    (ref) => ref.watch(apiClientProvider).getSupportGuides());

final supportGuideProvider = FutureProvider.family<SupportGuide, String>(
    (ref, slug) => ref.watch(apiClientProvider).getSupportGuide(slug));

/// Resolves a guide from either its slug or its industry display name (the
/// industry-selection cards still pass the name).
final supportGuideForIndustryProvider =
    FutureProvider.family<SupportGuide, String>((ref, value) async {
  final guides = await ref.watch(supportGuidesProvider.future);
  final normalized = value.trim().toLowerCase();
  SupportGuide? match;
  for (final guide in guides) {
    if (guide.slug.toLowerCase() == normalized ||
        guide.trackName.toLowerCase() == normalized) {
      match = guide;
      break;
    }
  }
  if (match == null) {
    throw StateError('Industry guide not found.');
  }
  return ref.watch(apiClientProvider).getSupportGuide(match.slug);
});

final supportAboutProvider = FutureProvider<SupportAbout>(
    (ref) => ref.watch(apiClientProvider).getSupportAbout());

final supportTicketsProvider = FutureProvider<List<SupportTicket>>(
    (ref) => ref.watch(apiClientProvider).getMyTickets());

final supportUnreadTicketsProvider = FutureProvider<int>(
    (ref) => ref.watch(apiClientProvider).getMyUnreadTicketCount());
