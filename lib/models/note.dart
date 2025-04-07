class Note {
  int? id;
  String title;
  String content;
  DateTime dateCreated;
  DateTime dateLastEdited;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.dateLastEdited,
  });

  Note copy({
    int? id,
    String? title,
    String? content,
    DateTime? dateCreated,
    DateTime? dateLastEdited,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        dateCreated: dateCreated ?? this.dateCreated,
        dateLastEdited: dateLastEdited ?? this.dateLastEdited,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateCreated': dateCreated.toIso8601String(),
      'dateLastEdited': dateLastEdited.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      dateCreated: DateTime.parse(map['dateCreated']),
      dateLastEdited: DateTime.parse(map['dateLastEdited']),
    );
  }
}