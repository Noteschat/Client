class Note {
  final String id;
  final String name;
  final String content;
  final String chatId;

  Note({required this.id, required this.name, required this.chatId, required this.content});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      chatId: json['chatId']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chatId': chatId,
      'content': content
    };
  }
}

class AllNote {
  final String name;
  final String id;

  AllNote({required this.name, required this.id});

  factory AllNote.fromJson(Map<String, dynamic> json) {
    return AllNote(
      name: json['name'],
      id: json['id'],
    );
  }
}