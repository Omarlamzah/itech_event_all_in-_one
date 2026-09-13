import 'dart:convert';

import 'package:http/http.dart' as http;

class EventMediaException implements Exception {
  const EventMediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EventMediaClient {
  EventMediaClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_URL',
            defaultValue:
                'https://events.itechevent.com/api/public/api/public/mobile',
          );

  final http.Client _client;
  final String _baseUrl;

  Future<EventMediaLibrary> fetchLibrary(String eventCode) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/events/$eventCode/media'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw EventMediaException(
        'Le serveur a retourné le code ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final meta = payload['meta'] as Map<String, dynamic>? ?? const {};
    return EventMediaLibrary(
      categories: (meta['categories'] as List<dynamic>? ?? const [])
          .map(
            (item) => EventMediaCategory.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      items: (payload['data'] as List<dynamic>? ?? const [])
          .map((item) => EventMediaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventMediaLibrary {
  const EventMediaLibrary({required this.categories, required this.items});

  final List<EventMediaCategory> categories;
  final List<EventMediaItem> items;
}

class EventMediaCategory {
  const EventMediaCategory({required this.key, required this.label});

  final String key;
  final String label;

  factory EventMediaCategory.fromJson(Map<String, dynamic> json) =>
      EventMediaCategory(
        key: json['key'] as String,
        label: json['label'] as String,
      );
}

class EventMediaItem {
  const EventMediaItem({
    required this.id,
    required this.category,
    required this.title,
    required this.mediaType,
    this.description,
    this.publishedOn,
    this.youtubeVideoId,
    this.externalUrl,
    this.fileUrl,
    this.thumbnailUrl,
    this.youtubeThumbnailUrl,
  });

  final int id;
  final String category;
  final String title;
  final String mediaType;
  final String? description;
  final DateTime? publishedOn;
  final String? youtubeVideoId;
  final String? externalUrl;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? youtubeThumbnailUrl;

  String? get coverUrl => thumbnailUrl ?? youtubeThumbnailUrl;

  String? get targetUrl {
    if (youtubeVideoId?.isNotEmpty ?? false) {
      return 'https://www.youtube.com/watch?v=$youtubeVideoId';
    }
    return externalUrl ?? fileUrl;
  }

  factory EventMediaItem.fromJson(Map<String, dynamic> json) => EventMediaItem(
    id: json['id'] as int,
    category: json['category'] as String,
    title: json['title'] as String,
    mediaType: json['media_type'] as String? ?? 'link',
    description: json['description'] as String?,
    publishedOn: DateTime.tryParse(json['published_on'] as String? ?? ''),
    youtubeVideoId: json['youtube_video_id'] as String?,
    externalUrl: json['external_url'] as String?,
    fileUrl: json['file_url'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
    youtubeThumbnailUrl: json['youtube_thumbnail_url'] as String?,
  );
}
