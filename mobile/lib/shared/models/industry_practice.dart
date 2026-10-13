// Industry Practice: informational workplace case studies. Plain class.
class IndustryCase {
  final int id;
  final String title;
  final String scenario;
  final String cause;
  final String solution;
  final String? sourceTitle;
  final String? sourceUrl;
  final bool read;

  const IndustryCase({
    required this.id,
    required this.title,
    this.scenario = '',
    this.cause = '',
    this.solution = '',
    this.sourceTitle,
    this.sourceUrl,
    this.read = false,
  });

  factory IndustryCase.fromJson(Map<String, dynamic> json) {
    final c = (json['case'] as Map?)?.cast<String, dynamic>() ?? json;
    return IndustryCase(
      id: int.tryParse('${c['id']}') ?? 0,
      title: c['title'] as String? ?? '',
      scenario: c['scenario'] as String? ?? '',
      cause: c['cause'] as String? ?? '',
      solution: c['solution'] as String? ?? '',
      sourceTitle: c['source_title'] as String?,
      sourceUrl: c['source_url'] as String?,
      read: c['read'] as bool? ?? false,
    );
  }
}
