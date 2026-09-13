import 'dart:convert';

import 'package:http/http.dart' as http;

class EventEposterException implements Exception {
  const EventEposterException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EventEposterClient {
  EventEposterClient({http.Client? client, String? baseUrl})
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

  Future<EventEposterLibrary> fetchLibrary(String eventCode) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/events/$eventCode/eposters'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw EventEposterException(
        'Le serveur a retourné le code ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final meta = payload['meta'] as Map<String, dynamic>? ?? const {};
    return EventEposterLibrary(
      categories: (meta['categories'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                EventEposterCategory.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      items: (payload['data'] as List<dynamic>? ?? const [])
          .map((item) => EventEposter.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<EposterComment>> fetchComments(
    String eventCode,
    int posterId,
  ) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/events/$eventCode/eposters/$posterId/comments'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const EventEposterException(
        'Impossible de charger les commentaires.',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['data'] as List<dynamic>? ?? const [])
        .map((item) => EposterComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EposterComment> postComment({
    required String eventCode,
    required int posterId,
    required String authorName,
    required String content,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/events/$eventCode/eposters/$posterId/comments'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'author_name': authorName, 'content': content}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw const EventEposterException(
        'Impossible de publier le commentaire.',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return EposterComment.fromJson(payload['data'] as Map<String, dynamic>);
  }
}

class EventEposterLibrary {
  const EventEposterLibrary({required this.categories, required this.items});

  final List<EventEposterCategory> categories;
  final List<EventEposter> items;
}

class EventEposterCategory {
  const EventEposterCategory({required this.key, required this.label});

  final String key;
  final String label;

  factory EventEposterCategory.fromJson(Map<String, dynamic> json) =>
      EventEposterCategory(
        key: json['key'] as String,
        label: json['label'] as String,
      );
}

class EventEposter {
  const EventEposter({
    required this.id,
    required this.title,
    required this.category,
    required this.pdfUrl,
    this.posterNumber,
    this.authors,
    this.affiliations,
    this.abstractText,
    this.keywords,
    this.award,
    this.coverUrl,
    this.originalFileName,
    this.fileSize,
    this.commentsCount = 0,
  });

  final int id;
  final String title;
  final String category;
  final String pdfUrl;
  final String? posterNumber;
  final String? authors;
  final String? affiliations;
  final String? abstractText;
  final String? keywords;
  final String? award;
  final String? coverUrl;
  final String? originalFileName;
  final int? fileSize;
  final int commentsCount;

  String get displayNumber =>
      posterNumber?.trim().isNotEmpty == true ? posterNumber!.trim() : 'EP-$id';

  factory EventEposter.fromJson(Map<String, dynamic> json) => EventEposter(
    id: json['id'] as int,
    title: json['title'] as String,
    category: json['category'] as String? ?? 'Général',
    pdfUrl: json['pdf_url'] as String,
    posterNumber: json['poster_number'] as String?,
    authors: json['authors'] as String?,
    affiliations: json['affiliations'] as String?,
    abstractText: json['abstract'] as String?,
    keywords: json['keywords'] as String?,
    award: json['award'] as String?,
    coverUrl: json['cover_url'] as String?,
    originalFileName: json['original_file_name'] as String?,
    fileSize: (json['file_size'] as num?)?.toInt(),
    commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
  );
}

class EposterComment {
  const EposterComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory EposterComment.fromJson(Map<String, dynamic> json) => EposterComment(
    id: json['id'] as int,
    authorName: json['author_name'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
