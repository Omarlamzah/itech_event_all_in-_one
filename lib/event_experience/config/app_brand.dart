import 'package:flutter/material.dart';

enum AppFeature {
  program,
  speakers,
  sponsors,
  mediaLibrary,
  eposters,
  floorPlan,
  voting,
  liveStream,
}

class AppBrand {
  const AppBrand({
    required this.code,
    required this.name,
    required this.fullName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.features,
    this.location = 'Morocco',
    this.year = '2026',
    this.description,
    this.heroImageUrl,
    this.programPdfUrl,
    this.venueName,
    this.mapUrl,
    this.presidentName,
    this.presidentMessage,
    this.presidentPhotoUrl,
    this.speakers = const [],
    this.sponsors = const [],
    this.boardMembers = const [],
    this.agenda = const [],
    this.startDate,
    this.endDate,
    this.registrationUrl,
    this.websiteUrl,
    this.specialty,
    this.expectedParticipants,
    this.contactEmail,
    this.contactPhone,
    this.liveStream,
  });

  final String code;
  final String name;
  final String fullName;
  final Color primaryColor;
  final Color secondaryColor;
  final Set<AppFeature> features;
  final String location;
  final String year;
  final String? description;
  final String? heroImageUrl;
  final String? programPdfUrl;
  final String? venueName;
  final String? mapUrl;
  final String? presidentName;
  final String? presidentMessage;
  final String? presidentPhotoUrl;
  final List<EventSpeaker> speakers;
  final List<EventSponsor> sponsors;
  final List<EventBoardMember> boardMembers;
  final List<AgendaItem> agenda;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? registrationUrl;
  final String? websiteUrl;
  final String? specialty;
  final int? expectedParticipants;
  final String? contactEmail;
  final String? contactPhone;
  final LiveStreamConfig? liveStream;

  bool supports(AppFeature feature) => features.contains(feature);

  String get logoAsset =>
      const {'agpc', 'somcep', 'ama', 'smcpre'}.contains(code)
      ? 'assets/branding/$code.png'
      : 'assets/branding/itechevent.png';

  bool get hasPresidentContent =>
      (presidentName?.trim().isNotEmpty ?? false) ||
      (presidentMessage?.trim().isNotEmpty ?? false) ||
      presidentPhotoUrl != null;

  factory AppBrand.fromApiJson(Map<String, dynamic> json) {
    final branding = json['branding'] as Map<String, dynamic>? ?? const {};
    final apiFeatures = json['features'] as List<dynamic>? ?? const [];
    final startsAt = DateTime.tryParse(json['starts_at'] as String? ?? '');
    final venue = json['venue'] as Map<String, dynamic>? ?? const {};
    final president = json['president'] as Map<String, dynamic>? ?? const {};
    final contact = json['contact'] as Map<String, dynamic>? ?? const {};
    final liveStream = json['live_stream'] as Map<String, dynamic>?;
    final code = json['code'] as String;
    final apiBoardMembers = (json['board'] as List<dynamic>? ?? const [])
        .map((item) => EventBoardMember.fromJson(item as Map<String, dynamic>))
        .toList();

    return AppBrand(
      code: code,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      primaryColor: _colorFromHex(branding['primary_color'] as String),
      secondaryColor: _colorFromHex(branding['secondary_color'] as String),
      location: json['location'] as String? ?? 'Morocco',
      year: startsAt?.year.toString() ?? '2026',
      description: json['description'] as String?,
      heroImageUrl: _mediaUrl(json['hero_image_url'] as String?),
      programPdfUrl: json['program_pdf_url'] as String?,
      venueName: venue['name'] as String?,
      mapUrl: venue['map_url'] as String?,
      presidentName: president['name'] as String?,
      presidentMessage: president['message'] as String?,
      presidentPhotoUrl: _mediaUrl(president['photo_url'] as String?),
      speakers: (json['speakers'] as List<dynamic>? ?? const [])
          .map((item) => EventSpeaker.fromJson(item as Map<String, dynamic>))
          .toList(),
      sponsors: (json['sponsors'] as List<dynamic>? ?? const [])
          .map((item) => EventSponsor.fromJson(item as Map<String, dynamic>))
          .toList(),
      boardMembers: apiBoardMembers.isEmpty && code.toLowerCase() == 'agpc'
          ? _agpcBoardMembers
          : apiBoardMembers,
      agenda: (json['agenda'] as List<dynamic>? ?? const [])
          .map((item) => AgendaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endDate: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      registrationUrl: json['registration_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      specialty: json['specialty'] as String?,
      expectedParticipants: json['expected_participants'] as int?,
      contactEmail: contact['email'] as String?,
      contactPhone: contact['phone'] as String?,
      liveStream: liveStream == null
          ? null
          : LiveStreamConfig.fromJson(liveStream),
      features: {
        ...apiFeatures
            .map((feature) => _featureFromApi(feature as String))
            .whereType<AppFeature>(),
        if ((json['code'] as String).toLowerCase() == 'agpc')
          AppFeature.mediaLibrary,
      },
    );
  }

  static Color _colorFromHex(String value) {
    return Color(int.parse(value.replaceFirst('#', 'FF'), radix: 16));
  }

  static String? _mediaUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.path.startsWith('/storage/')) {
      return value;
    }
    final mediaPath = uri.path.substring('/storage/'.length);
    return uri
        .replace(
          path: '/api/public/link/$mediaPath',
          query: null,
          fragment: null,
        )
        .toString();
  }

  static AppFeature? _featureFromApi(String value) => switch (value) {
    'program' => AppFeature.program,
    'speakers' => AppFeature.speakers,
    'sponsors' => AppFeature.sponsors,
    'media_library' => AppFeature.mediaLibrary,
    'eposters' => AppFeature.eposters,
    'floor_plan' => AppFeature.floorPlan,
    'voting' => AppFeature.voting,
    'live_stream' => AppFeature.liveStream,
    _ => null,
  };

  static AppBrand fromEnvironment() {
    const flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'somcep');
    return brands[flavor] ?? brands['somcep']!;
  }

  static const brands = <String, AppBrand>{
    'agpc': AppBrand(
      code: 'agpc',
      name: 'AGPC',
      fullName: 'AGPC Annual Congress',
      primaryColor: Color(0xFF006B5B),
      secondaryColor: Color(0xFFBFE7D8),
      features: {
        AppFeature.program,
        AppFeature.speakers,
        AppFeature.sponsors,
        AppFeature.mediaLibrary,
        AppFeature.eposters,
        AppFeature.voting,
      },
      boardMembers: _agpcBoardMembers,
    ),
    'somcep': AppBrand(
      code: 'somcep',
      name: 'SOMCEP',
      fullName: 'SOMCEP Annual Congress',
      primaryColor: Color(0xFF2C3373),
      secondaryColor: Color(0xFFB4E1FA),
      features: {
        AppFeature.program,
        AppFeature.speakers,
        AppFeature.sponsors,
        AppFeature.floorPlan,
        AppFeature.eposters,
      },
    ),
    'ama': AppBrand(
      code: 'ama',
      name: 'AMA',
      fullName: 'AMA Annual Meeting',
      primaryColor: Color(0xFF9A3412),
      secondaryColor: Color(0xFFFED7AA),
      features: {
        AppFeature.program,
        AppFeature.speakers,
        AppFeature.sponsors,
        AppFeature.liveStream,
        AppFeature.eposters,
      },
    ),
    'smcpre': AppBrand(
      code: 'smcpre',
      name: 'SMCPRE',
      fullName: 'SMCPRE Annual Congress',
      primaryColor: Color(0xFF7C2D68),
      secondaryColor: Color(0xFFF5D0E8),
      features: {
        AppFeature.program,
        AppFeature.speakers,
        AppFeature.sponsors,
        AppFeature.eposters,
      },
    ),
  };

  static const _agpcBoardMembers = <EventBoardMember>[
    EventBoardMember(
      name: 'Dr Mohamed Kamal Benhayoun',
      role: 'Président',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/kbenhayoun.png',
    ),
    EventBoardMember(
      name: 'Dr Mostafa Sabir',
      role: '1er Vice-Président',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/msabir.png',
    ),
    EventBoardMember(
      name: 'Dr Omar Lahlou',
      role: '2è Vice-Président',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/olahlou.png',
    ),
    EventBoardMember(
      name: 'Dr Naima Jebrane',
      role: 'Secrétaire Général',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/jabrane.jpeg',
    ),
    EventBoardMember(
      name: 'Dr Mohamed Boutaleb',
      role: 'Secrétaire Général Adjoint',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/mboutaieb.png',
    ),
    EventBoardMember(
      name: 'Dr Abdelfettah Lahlou',
      role: 'Trésorier',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/alahlou.png',
    ),
    EventBoardMember(
      name: 'Dr Meriem Ouadine',
      role: 'Trésorier adjoint',
      photoUrl:
          'https://events.itechevent.com/api/public/link/mobile-apps/9/board/avatar.jpg',
    ),
  ];
}

class LiveStreamConfig {
  const LiveStreamConfig({
    required this.title,
    required this.isLive,
    required this.isPublished,
    required this.commentsEnabled,
    this.description,
    this.sourceUrl,
    this.youtubeVideoId,
    this.commentsUrl,
  });

  final String title;
  final String? description;
  final String? sourceUrl;
  final String? youtubeVideoId;
  final bool isLive;
  final bool isPublished;
  final bool commentsEnabled;
  final String? commentsUrl;

  bool get isAvailable => isPublished && youtubeVideoId != null;

  factory LiveStreamConfig.fromJson(Map<String, dynamic> json) =>
      LiveStreamConfig(
        title: json['title'] as String? ?? 'Direct',
        description: json['description'] as String?,
        sourceUrl: json['source_url'] as String?,
        youtubeVideoId: json['youtube_video_id'] as String?,
        isLive: json['is_live'] as bool? ?? false,
        isPublished: json['is_published'] as bool? ?? false,
        commentsEnabled: json['comments_enabled'] as bool? ?? false,
        commentsUrl: json['comments_url'] as String?,
      );
}

class AgendaItem {
  const AgendaItem({
    this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.description,
    this.speakerName,
    this.speakerTitle,
    this.room,
    this.type,
    this.colorHex,
  });
  final int? id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? description;
  final String? speakerName;
  final String? speakerTitle;
  final String? room;
  final String? type;
  final String? colorHex;

  String get storageKey =>
      id?.toString() ?? '$title|${startAt.toIso8601String()}';

  factory AgendaItem.fromJson(Map<String, dynamic> json) => AgendaItem(
    id: json['id'] as int?,
    title: json['title'] as String,
    startAt: DateTime.parse(json['start_at'] as String),
    endAt: DateTime.parse(json['end_at'] as String),
    description: json['description'] as String?,
    speakerName: json['speaker_name'] as String?,
    speakerTitle: json['speaker_title'] as String?,
    room: json['room'] as String?,
    type: json['type'] as String?,
    colorHex: json['color'] as String?,
  );
}

class EventSpeaker {
  const EventSpeaker({
    required this.name,
    required this.category,
    this.title,
    this.country,
    this.bio,
    this.photoUrl,
  });
  final String name;
  final String category;
  final String? title;
  final String? country;
  final String? bio;
  final String? photoUrl;

  factory EventSpeaker.fromJson(Map<String, dynamic> json) => EventSpeaker(
    name: json['name'] as String,
    category: json['category'] as String,
    title: json['title'] as String?,
    country: json['country'] as String?,
    bio: json['bio'] as String?,
    photoUrl: AppBrand._mediaUrl(json['photo_url'] as String?),
  );
}

class EventSponsor {
  const EventSponsor({
    required this.name,
    required this.level,
    this.websiteUrl,
    this.logoUrl,
  });
  final String name;
  final String level;
  final String? websiteUrl;
  final String? logoUrl;

  factory EventSponsor.fromJson(Map<String, dynamic> json) => EventSponsor(
    name: json['name'] as String,
    level: json['level'] as String,
    websiteUrl: json['website_url'] as String?,
    logoUrl: AppBrand._mediaUrl(json['logo_url'] as String?),
  );
}

class EventBoardMember {
  const EventBoardMember({
    required this.name,
    required this.role,
    this.bio,
    this.photoUrl,
  });

  final String name;
  final String role;
  final String? bio;
  final String? photoUrl;

  factory EventBoardMember.fromJson(Map<String, dynamic> json) =>
      EventBoardMember(
        name: json['name'] as String,
        role: json['role'] as String,
        bio: json['bio'] as String?,
        photoUrl: AppBrand._mediaUrl(json['photo_url'] as String?),
      );
}
