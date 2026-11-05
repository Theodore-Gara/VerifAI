// Verification Studio: analysis report + sources. Plain classes (no codegen).
import 'vera.dart' show VeraSource;

class VerificationSourceInput {
  final String type; // text | url | citation | document
  final String? text;
  final String? url;
  final String? name;
  final String? mime;
  final String? base64;
  final String? label;

  const VerificationSourceInput({
    required this.type,
    this.text,
    this.url,
    this.name,
    this.mime,
    this.base64,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        if (text != null) 'text': text,
        if (url != null) 'url': url,
        if (name != null) 'name': name,
        if (mime != null) 'mime': mime,
        if (base64 != null) 'base64': base64,
        if (label != null) 'label': label,
      };
}

class VerificationItem {
  final String claim;
  final String concern;

  const VerificationItem({required this.claim, required this.concern});

  factory VerificationItem.fromJson(Map<String, dynamic> json) =>
      VerificationItem(
        claim: json['claim'] as String? ?? '',
        concern: json['concern'] as String? ?? '',
      );
}

class VerificationInput {
  final String type;
  final String label;
  final int chars;
  final int? pages;
  final int? pagesRead;
  final bool truncated;
  final String? quality;
  final String? warning;

  const VerificationInput({
    required this.type,
    required this.label,
    required this.chars,
    this.pages,
    this.pagesRead,
    this.truncated = false,
    this.quality,
    this.warning,
  });

  factory VerificationInput.fromJson(Map<String, dynamic> json) =>
      VerificationInput(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        chars: int.tryParse('${json['chars']}') ?? 0,
        pages: int.tryParse('${json['pages']}'),
        pagesRead: int.tryParse('${json['pages_read']}'),
        truncated: json['truncated'] as bool? ?? false,
        quality: json['quality'] as String?,
        warning: json['warning'] as String?,
      );
}

/// What actually ran, from the v2 report. Null on legacy (version 1) rows.
class VerificationChecks {
  final bool webSearch;
  final int sourcesFound;
  final int claimsChecked;
  final int citationsChecked;

  const VerificationChecks({
    this.webSearch = false,
    this.sourcesFound = 0,
    this.claimsChecked = 0,
    this.citationsChecked = 0,
  });

  factory VerificationChecks.fromJson(Map<String, dynamic> json) =>
      VerificationChecks(
        webSearch: json['web_search'] as bool? ?? false,
        sourcesFound: int.tryParse('${json['sources_found']}') ?? 0,
        claimsChecked: int.tryParse('${json['claims_checked']}') ?? 0,
        citationsChecked: int.tryParse('${json['citations_checked']}') ?? 0,
      );
}

class VerificationClaim {
  final String claim;
  final String verdict; // supported | contradicted | unverified
  final String concern;
  final int? page;
  final List<VeraSource> evidence;

  const VerificationClaim({
    required this.claim,
    required this.verdict,
    this.concern = '',
    this.page,
    this.evidence = const [],
  });

  factory VerificationClaim.fromJson(Map<String, dynamic> json) =>
      VerificationClaim(
        claim: json['claim'] as String? ?? '',
        verdict: json['verdict'] as String? ?? 'unverified',
        concern: json['concern'] as String? ?? '',
        page: int.tryParse('${json['page']}'),
        evidence: ((json['evidence'] as List<dynamic>?) ?? const [])
            .map(
                (e) => VeraSource.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class VerificationResult {
  final int id;
  final int version;
  final String kind;
  final String? documentName;
  final String overallStatus;
  final List<VerificationItem> items;
  final List<VerificationClaim> claims;
  final VerificationChecks? checks;
  final int sourcesConfirmed;
  final String summary;
  final List<VeraSource> sources;
  final List<VerificationInput> inputs;
  final bool webSearched;
  final String? createdAt;

  const VerificationResult({
    required this.id,
    this.version = 1,
    required this.kind,
    this.documentName,
    required this.overallStatus,
    this.items = const [],
    this.claims = const [],
    this.checks,
    this.sourcesConfirmed = 0,
    this.summary = '',
    this.sources = const [],
    this.inputs = const [],
    this.webSearched = false,
    this.createdAt,
  });

  bool get needsReview =>
      overallStatus == 'human_review_required' ||
      overallStatus == 'insufficient_evidence';

  /// Green is only allowed when a source was actually found and at least one
  /// claim was checked. A legacy row (no checks) can never prove that.
  bool get isSound =>
      overallStatus == 'appears_sound' &&
      checks != null &&
      checks!.sourcesFound > 0 &&
      checks!.claimsChecked > 0;

  /// Parses the `analysis` row plus the top-level `sources`/`inputs` of the
  /// analyze response, or a stored analysis row from the history list. Note the
  /// row's `items_requiring_review` is a COUNT; the list lives in `report`.
  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final analysis =
        (json['analysis'] as Map?)?.cast<String, dynamic>() ?? json;
    final report =
        (analysis['report'] as Map?)?.cast<String, dynamic>() ?? const {};
    final items =
        (report['items_requiring_review'] as List<dynamic>? ?? const [])
            .map((e) =>
                VerificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    final claimsJson =
        (analysis['claims'] as List<dynamic>?) ?? const <dynamic>[];
    final sourcesJson = (json['sources'] as List<dynamic>?) ??
        (report['sources'] as List<dynamic>?) ??
        const [];
    final inputsJson = json['inputs'] as List<dynamic>? ?? const [];
    final checksJson = analysis['checks'] as Map?;
    return VerificationResult(
      id: int.tryParse('${analysis['id']}') ?? 0,
      version: int.tryParse('${analysis['version']}') ?? 1,
      kind: analysis['kind'] as String? ?? '',
      documentName: analysis['document_name'] as String?,
      overallStatus:
          analysis['overall_status'] as String? ?? 'human_review_required',
      items: items,
      claims: claimsJson
          .map((e) =>
              VerificationClaim.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      checks: checksJson == null
          ? null
          : VerificationChecks.fromJson(checksJson.cast<String, dynamic>()),
      sourcesConfirmed: int.tryParse('${analysis['sources_confirmed']}') ?? 0,
      summary: analysis['summary'] as String? ?? '',
      sources: sourcesJson
          .map((e) => VeraSource.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      inputs: inputsJson
          .map((e) =>
              VerificationInput.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      webSearched: json['web_searched'] as bool? ??
          (checksJson?['web_search'] as bool?) ??
          false,
      createdAt: analysis['created_at'] as String?,
    );
  }
}

/// Limits from `GET /api/meta`; the app must not hardcode a different value.
class VerificationMeta {
  final int maxDocumentBytes;
  final int maxPages;
  final int maxTotalChars;
  final List<String> acceptedFormats;

  const VerificationMeta({
    this.maxDocumentBytes = 5 * 1024 * 1024,
    this.maxPages = 40,
    this.maxTotalChars = 60000,
    this.acceptedFormats = const ['pdf', 'docx', 'txt', 'md'],
  });

  factory VerificationMeta.fromJson(Map<String, dynamic> json) {
    final verification =
        (json['verification'] as Map?)?.cast<String, dynamic>() ?? const {};
    return VerificationMeta(
      maxDocumentBytes: int.tryParse('${verification['max_document_bytes']}') ??
          5 * 1024 * 1024,
      maxPages: int.tryParse('${verification['max_pages']}') ?? 40,
      maxTotalChars:
          int.tryParse('${verification['max_total_chars']}') ?? 60000,
      acceptedFormats: ((verification['accepted_formats'] as List<dynamic>?) ??
              const ['pdf', 'docx', 'txt', 'md'])
          .map((e) => e.toString())
          .toList(),
    );
  }

  String get maxFileLabel {
    final mb = maxDocumentBytes / (1024 * 1024);
    return mb >= 1
        ? '${mb.toStringAsFixed(mb == mb.round() ? 0 : 1)} MB'
        : '${(maxDocumentBytes / 1024).round()} KB';
  }

  String get formatsLabel =>
      acceptedFormats.map((format) => format.toUpperCase()).join(', ');
}
