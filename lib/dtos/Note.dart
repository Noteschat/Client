class Note {
  final String id;
  final String name;
  final String content;
  final String chatId;
  final List<String> tags;

  Note({
    required this.id,
    required this.name,
    required this.chatId,
    required this.content,
    this.tags = const [],
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] != null) {
      for (String tag in json['tags']) {
        tags.add(tag);
      }
    }
    return Note(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      chatId: json['chatId'],
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chatId': chatId,
      'content': content,
      'tags': tags,
    };
  }
}

class AllNote {
  final String name;
  final String id;
  final List<String> tags;

  AllNote({required this.name, required this.id, this.tags = const []});

  factory AllNote.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] != null) {
      for (String tag in json['tags']) {
        tags.add(tag);
      }
    }
    return AllNote(name: json['name'], id: json['id'], tags: tags);
  }
}
