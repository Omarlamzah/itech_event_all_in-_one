import '../models/participant.dart';
import 'api_service.dart';

class ParticipantService {
  final ApiService _api = ApiService();

  Future<List<Participant>> getParticipants(int eventId, {String? search}) async {
    final response = await _api.get(
      '/events/$eventId/participants',
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] ?? []);
    return (list as List).map((e) => Participant.fromJson(e)).toList();
  }

  Future<Participant> getParticipant(int eventId, int participantId) async {
    final response = await _api.get('/events/$eventId/participants/$participantId');
    return Participant.fromJson(response.data);
  }

  Future<Participant> createParticipant(int eventId, Map<String, dynamic> data) async {
    final response = await _api.post('/events/$eventId/participants', data: data);
    return Participant.fromJson(response.data);
  }

  Future<Participant> updateParticipant(int eventId, int participantId, Map<String, dynamic> data) async {
    final response = await _api.put('/events/$eventId/participants/$participantId', data: data);
    return Participant.fromJson(response.data);
  }

  Future<void> deleteParticipant(int eventId, int participantId) async {
    await _api.delete('/events/$eventId/participants/$participantId');
  }

  Future<Participant?> findByBarcode(String barcode) async {
    final response = await _api.post('/participants/barcode', data: {'codebare': barcode});
    return Participant.fromJson(response.data);
  }
}
