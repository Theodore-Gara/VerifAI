/// Content and ticket models for the support surface.
///
/// These mirror `GET /api/support/*` and `GET /api/support/tickets`.
class SupportHelpArticle {
  final int id;
  final String slug;
  final String title;
  final String summary;
  final String bodyMd;
  final String category;
  final String? audience;

  const SupportHelpArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.bodyMd,
    required this.category,
    this.audience,
  });

  factory SupportHelpArticle.fromJson(Map<String, dynamic> json) =>
      SupportHelpArticle(
        id: _int(json['id']),
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        bodyMd: json['body_md'] as String? ?? '',
        category: json['category'] as String? ?? 'start',
        audience: json['audience'] as String?,
      );
}

class SupportFaq {
  final int id;
  final String slug;
  final String question;
  final String answerMd;
  final String topic;

  const SupportFaq({
    required this.id,
    required this.slug,
    required this.question,
    required this.answerMd,
    required this.topic,
  });

  factory SupportFaq.fromJson(Map<String, dynamic> json) => SupportFaq(
        id: _int(json['id']),
        slug: json['slug'] as String? ?? '',
        question: json['question'] as String? ?? '',
        answerMd: json['answer_md'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
      );
}

class SupportGuide {
  final int id;
  final int trackId;
  final String trackName;
  final String slug;
  final String tagline;
  final String overviewMd;
  final Map<String, dynamic> outcomes;
  final List<dynamic> featureTour;
  final Map<String, dynamic> howTo;
  final String? heroImage;
  final String? bodyImage;

  const SupportGuide({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.slug,
    required this.tagline,
    required this.overviewMd,
    this.outcomes = const {},
    this.featureTour = const [],
    this.howTo = const {},
    this.heroImage,
    this.bodyImage,
  });

  factory SupportGuide.fromJson(Map<String, dynamic> json) => SupportGuide(
        id: _int(json['id']),
        trackId: _int(json['track_id']),
        trackName: json['track_name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        tagline: json['tagline'] as String? ?? '',
        overviewMd: json['overview_md'] as String? ?? '',
        outcomes: _map(json['outcomes']),
        featureTour:
            (json['feature_tour'] as List<dynamic>?) ?? const <dynamic>[],
        howTo: _map(json['how_to']),
        heroImage: json['hero_image'] as String?,
        bodyImage: json['body_image'] as String?,
      );
}

class SupportAbout {
  final String title;
  final Map<String, dynamic> data;
  final String? email;
  final String? expectedReply;
  final String? appVersion;

  const SupportAbout({
    required this.title,
    this.data = const {},
    this.email,
    this.expectedReply,
    this.appVersion,
  });

  factory SupportAbout.fromJson(Map<String, dynamic> json) {
    final about = _map(json['about']);
    final contact = _map(about['contact']);
    return SupportAbout(
      title: about['title'] as String? ?? 'About VerifAI',
      data: about,
      email: contact['email'] as String?,
      expectedReply: contact['expected_reply'] as String?,
      appVersion: about['app_version'] as String?,
    );
  }
}

class SupportTicket {
  final int id;
  final String publicRef;
  final String subject;
  final String category;
  final String status;
  final String? name;
  final String? email;
  final String? message;
  final String? createdAt;
  final String? updatedAt;
  final String? lastReplyAt;
  final String? resolvedAt;
  final int replyCount;
  final bool unread;

  const SupportTicket({
    required this.id,
    required this.publicRef,
    required this.subject,
    required this.category,
    required this.status,
    this.name,
    this.email,
    this.message,
    this.createdAt,
    this.updatedAt,
    this.lastReplyAt,
    this.resolvedAt,
    this.replyCount = 0,
    this.unread = false,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: _int(json['id']),
        publicRef: json['public_ref'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        status: json['status'] as String? ?? 'new',
        name: json['name'] as String?,
        email: json['email'] as String?,
        message: json['message'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        lastReplyAt: json['last_reply_at'] as String?,
        resolvedAt: json['resolved_at'] as String?,
        replyCount: _int(json['reply_count']),
        unread: json['unread'] as bool? ?? false,
      );
}

class SupportReply {
  final int id;
  final String authorType;
  final String body;
  final String? createdAt;

  const SupportReply({
    required this.id,
    required this.authorType,
    required this.body,
    this.createdAt,
  });

  factory SupportReply.fromJson(Map<String, dynamic> json) => SupportReply(
        id: _int(json['id']),
        authorType: json['author_type'] as String? ?? 'admin',
        body: json['body'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}

class SupportTicketDetail {
  final SupportTicket ticket;
  final List<SupportReply> replies;

  const SupportTicketDetail({required this.ticket, required this.replies});
}

class SupportContactResult {
  final String ticketId;
  final String expectedReply;

  const SupportContactResult({
    required this.ticketId,
    required this.expectedReply,
  });

  factory SupportContactResult.fromJson(Map<String, dynamic> json) =>
      SupportContactResult(
        ticketId: json['ticket_id'] as String? ?? '',
        expectedReply: json['expected_reply'] as String? ?? '',
      );
}

int _int(dynamic value) => int.tryParse('$value') ?? 0;
Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
