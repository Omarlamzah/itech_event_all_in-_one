import 'dart:convert';

import 'package:http/http.dart' as http;

class LiveComment {
  const LiveComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory LiveComment.fromJson(Map<String, dynamic> json) => LiveComment(
    id: json['id'] as int,
    authorName: json['author_name'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class LiveCommentClient {
  LiveCommentClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LiveComment>> fetch(String url) async {
    final response = await _client
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les commentaires.');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => LiveComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LiveComment> post({
    required String url,
    required String authorName,
    required String content,
  }) async {
    final response = await _client
        .post(
          Uri.parse(url),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'author_name': authorName, 'content': content}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw Exception('Impossible d’envoyer le commentaire.');
    }
    return LiveComment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
