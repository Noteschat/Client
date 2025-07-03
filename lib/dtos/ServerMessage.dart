class ServerMessage {
  final int version;
  final String messageId;
  final String content;
  final String chatId;
  final String userId;

  ServerMessage({required this.version, required this.messageId, required this.content, required this.chatId, required this.userId});

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return ServerMessage(
      version: json['version'],
      messageId: json['messageId'],
      content: json['content'],
      chatId: json['chatId'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'messageId': messageId,
      'content': content,
      'chatId': chatId,
      'userId': userId,
    };
  }
}
