class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String priority;
  final String category;
  final String universityId;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.priority,
    required this.category,
    required this.universityId,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      priority: json['priority'],
      category: json['category'],
      universityId: json['university_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'priority': priority,
      'category': category,
      'university_id': universityId,
    };
  }
}
