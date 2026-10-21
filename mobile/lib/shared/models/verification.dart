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

  const VerificationInput(
      {required this.type, required this.label, required this.chars});

  factory VerificationInput.fromJson(Map<String, dynamic> json) =>
      VerificationInput(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        chars: int.tryParse('${json['chars']}') ?? 0,
      );
}

class VerificationResult {
  final int id;
  final String kind;
  final String? documentName;
  final String overallStatus;
  final List<VerificationItem> items;
  final int sourcesConfirmed;
  final String summary;
  final List<VeraSource> sources;
  final List<VerificationInput> inputs;
  final bool webSearched;
  final String? createdAt;

  const VerificationResult({
    required this.id,
    required this.kind,
    this.documentName,
    required this.overallStatus,
    this.items = const [],
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
    final sourcesJson = (json['sources'] as List<dynamic>?) ??
        (report['sources'] as List<dynamic>?) ??
        const [];
    final inputsJson = json['inputs'] as List<dynamic>? ?? const [];
    return VerificationResult(
      id: int.tryParse('${analysis['id']}') ?? 0,
      kind: analysis['kind'] as String? ?? '',
      documentName: analysis['document_name'] as String?,
      overallStatus:
          analysis['overall_status'] as String? ?? 'human_review_required',
      items: items,
      sourcesConfirmed: int.tryParse('${analysis['sources_confirmed']}') ?? 0,
      summary: analysis['summary'] as String? ?? '',
      sources: sourcesJson
          .map((e) => VeraSource.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      inputs: inputsJson
          .map((e) =>
              VerificationInput.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      webSearched: json['web_searched'] as bool? ?? false,
      createdAt: analysis['created_at'] as String?,
    );
  }
}
