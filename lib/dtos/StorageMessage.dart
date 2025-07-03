class StorageMessage {
  final int version;
  final String messageId;
  final String content;
  final String userId;

  StorageMessage({required this.version, required this.messageId, required this.content, required this.userId});

  factory StorageMessage.fromJson(Map<String, dynamic> json) {
    return StorageMessage(
      version: json['version'],
      messageId: json['messageId'],
      content: json['content'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'messageId': messageId,
      'content': content,
      'userId': userId,
    };
  }
}
