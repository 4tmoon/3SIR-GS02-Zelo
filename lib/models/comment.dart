class Comment {
  final String id;
  final String issueId;
  final String author;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.issueId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'issueId': issueId,
        'author': author,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        id: map['id'] as String,
        issueId: map['issueId'] as String,
        author: map['author'] as String,
        text: map['text'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}