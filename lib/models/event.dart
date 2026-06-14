class Event {
  final int id;
  final String name;
  final String? location;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int? participantsCount;
  final String? eventImg;

  Event({
    required this.id,
    required this.name,
    this.location,
    this.description,
    this.startDate,
    this.endDate,
    this.participantsCount,
    this.eventImg,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'] ?? '',
      location: json['location'],
      description: json['description'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      participantsCount: json['participants_count'],
      eventImg: json['event_img'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
      };
}
