import '../models/agenda_session.dart';
import 'api_service.dart';

class AgendaService {
  final ApiService _api = ApiService();

  Future<List<AgendaSession>> getSessions(int eventId) async {
    final response = await _api.get('/events/$eventId/agenda');
    final data = response.data;
    final list = data is List ? data : (data['data'] ?? []);
    return (list as List).map((e) => AgendaSession.fromJson(e)).toList();
  }
}
