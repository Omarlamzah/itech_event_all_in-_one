class AgendaSession {
  final int id;
  final String title;
  final String? description;
  final String? speaker;
  final String? startAt;
  final String? endAt;
  final String? room;
  final Map<String, dynamic>? type;

  AgendaSession({
    required this.id,
    required this.title,
    this.description,
    this.speaker,
    this.startAt,
    this.endAt,
    this.room,
    this.type,
  });

  factory AgendaSession.fromJson(Map<String, dynamic> json) {
    return AgendaSession(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      speaker: json['speaker'],
      startAt: json['start_at'],
      endAt: json['end_at'],
      room: json['room'],
      type: json['type'] is Map ? Map<String, dynamic>.from(json['type']) : null,
    );
  }

  String get typeName => type?['name'] ?? '';
  String get typeColor => type?['color'] ?? '#2196F3';
}
