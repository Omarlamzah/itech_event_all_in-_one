import '../services/api_service.dart';

class AiChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String? sql;
  final List<Map<String, dynamic>>? results;

  const AiChatMessage({
    required this.role,
    required this.content,
    this.sql,
    this.results,
  });
}

class AiChatService {
  final ApiService _api = ApiService();

  Future<AiChatMessage> sendMessage(String message) async {
    final response = await _api.post('/ai/chat', data: {'message': message});
    final data = response.data as Map<String, dynamic>;

    List<Map<String, dynamic>>? results;
    if (data['results'] is List) {
      results = (data['results'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return AiChatMessage(
      role: 'assistant',
      content: data['answer'] as String? ?? 'No answer.',
      sql: data['sql'] as String?,
      results: results,
    );
  }
}
