/// Represents a chat message in the AI Safety Assistant.
class AiMessageModel {
  const AiMessageModel({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isFromUser = true,
    this.isTyping = false,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final bool isFromUser;
  final bool isTyping; // shows typing animation bubble

  factory AiMessageModel.user(String content) {
    return AiMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      isFromUser: true,
    );
  }

  factory AiMessageModel.ai(String content) {
    return AiMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      isFromUser: false,
    );
  }

  factory AiMessageModel.typing() {
    return AiMessageModel(
      id: 'typing',
      content: '',
      createdAt: DateTime.now(),
      isFromUser: false,
      isTyping: true,
    );
  }
}
