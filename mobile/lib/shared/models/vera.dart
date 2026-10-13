// Vera AI assistant — chat sessions, messages, memory and tips.
// Plain classes (no codegen).

class VeraSession {
  final int id;
  final String context;
  final String? title;
  final String startedAt;
  final String lastActiveAt;
  final int messageCount;

  const VeraSession({
    required this.id,
    required this.context,
    this.title,
    required this.startedAt,
    required this.lastActiveAt,
    required this.messageCount,
  });

  factory VeraSession.fromJson(Map<String, dynamic> json) => VeraSession(
        id: int.tryParse('${json['id']}') ?? 0,
        context: json['context'] as String? ?? 'assistant',
        title: json['title'] as String?,
        startedAt: json['started_at'] as String? ?? '',
        lastActiveAt: json['last_active_at'] as String? ?? '',
        messageCount: int.tryParse('${json['message_count']}') ?? 0,
      );
}

class VeraMessage {
  final int id;
  final String role;
  final String content;
  final String createdAt;

  const VeraMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get fromAssistant => role == 'assistant';

  factory VeraMessage.fromJson(Map<String, dynamic> json) => VeraMessage(
        id: int.tryParse('${json['id']}') ?? 0,
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class VeraSessionDetail {
  final VeraSession session;
  final List<VeraMessage> messages;

  const VeraSessionDetail({required this.session, required this.messages});

  factory VeraSessionDetail.fromJson(Map<String, dynamic> json) => VeraSessionDetail(
        session: VeraSession.fromJson(
            Map<String, dynamic>.from(json['session'] as Map? ?? const {})),
        messages: ((json['messages'] as List<dynamic>?) ?? const [])
            .map((e) => VeraMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class VeraMemory {
  final int id;
  final String kind;
  final String content;
  final String source;
  final String createdAt;
  final String updatedAt;

  const VeraMemory({
    required this.id,
    required this.kind,
    required this.content,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VeraMemory.fromJson(Map<String, dynamic> json) => VeraMemory(
        id: int.tryParse('${json['id']}') ?? 0,
        kind: json['kind'] as String? ?? 'fact',
        content: json['content'] as String? ?? '',
        source: json['source'] as String? ?? 'chat',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class VeraTip {
  final String title;
  final String body;

  const VeraTip({required this.title, required this.body});

  factory VeraTip.fromJson(Map<String, dynamic> json) => VeraTip(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

/// Result of a non-streaming Vera turn.
class VeraChatResult {
  final int sessionId;
  final String reply;
  final List<VeraSource> sources;
  final bool webSearched;

  const VeraChatResult({
    required this.sessionId,
    required this.reply,
    this.sources = const [],
    this.webSearched = false,
  });
}

/// A cited source returned by Vera / the Verification Studio.
class VeraSource {
  final String title;
  final String url;

  const VeraSource({required this.title, required this.url});

  factory VeraSource.fromJson(Map<String, dynamic> json) => VeraSource(
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}
