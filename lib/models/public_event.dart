class PublicEvent {
  const PublicEvent({
    required this.id,
    required this.name,
    this.fullName,
    this.startDate,
    this.endDate,
    this.location,
    this.description,
    this.imageUrl,
    this.registrationUrl,
    this.programUrl,
    this.programTitle,
    this.mobileCode,
    this.primaryColorHex,
    this.secondaryColorHex,
    this.features = const [],
    this.participantsCount = 0,
  });

  final int id;
  final String name;
  final String? fullName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? description;
  final String? imageUrl;
  final String? registrationUrl;
  final String? programUrl;
  final String? programTitle;
  final String? mobileCode;
  final String? primaryColorHex;
  final String? secondaryColorHex;
  final List<String> features;
  final int participantsCount;

  bool get hasEventApp => mobileCode?.isNotEmpty == true;
  bool get isPast => endDate != null && endDate!.isBefore(_today);
  bool get isLive {
    final start = startDate;
    if (start == null) return false;
    final end = endDate ?? start;
    return !start.isAfter(_today) && !end.isBefore(_today);
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    final mobile = json['mobile_app'] is Map
        ? Map<String, dynamic>.from(json['mobile_app'] as Map)
        : const <String, dynamic>{};
    return PublicEvent(
      id: _asInt(json['id']),
      name: (json['name'] ?? 'Événement').toString(),
      fullName: mobile['full_name']?.toString(),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? ''),
      location: json['location']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      registrationUrl: json['registration_url']?.toString(),
      programUrl: json['program_url']?.toString(),
      programTitle: json['program_title']?.toString(),
      mobileCode: mobile['code']?.toString(),
      primaryColorHex: mobile['primary_color']?.toString(),
      secondaryColorHex: mobile['secondary_color']?.toString(),
      features: (mobile['features'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      participantsCount: _asInt(json['participants_count']),
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
