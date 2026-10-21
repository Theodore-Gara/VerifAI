/// Assistant chat session for a specific task.
class AssistantSession {
  final int id;
  final String startedAt;
  final String lastActiveAt;
  final int messageCount;

  const AssistantSession({
    required this.id,
    required this.startedAt,
    required this.lastActiveAt,
    required this.messageCount,
  });

  factory AssistantSession.fromJson(Map<String, dynamic> json) =>
      AssistantSession(
        id: int.tryParse('${json['id']}') ?? 0,
        startedAt: json['started_at'] as String? ?? '',
        lastActiveAt: json['last_active_at'] as String? ?? '',
        messageCount: int.tryParse('${json['message_count']}') ?? 0,
      );
}

/// A single message in an assistant conversation.
class AssistantMessageModel {
  final int id;
  final String role;
  final String content;
  final String createdAt;

  const AssistantMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get fromAssistant => role == 'assistant';

  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) =>
      AssistantMessageModel(
        id: int.tryParse('${json['id']}') ?? 0,
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

  /// Convert to the API client's AssistantMessage format.
  Map<String, String> toApiJson() => {'role': role, 'content': content};
}
