import 'api_service.dart';

class CheckInService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> scan(String barcode) async {
    final response = await _api.post('/checkin', data: {'codebare': barcode});
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> resetCheckIn(int participantId) async {
    await _api.delete('/participants/$participantId/checkin');
  }

  Future<Map<String, dynamic>> getStats(int eventId) async {
    final response = await _api.get('/events/$eventId/checkin-stats');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getHistory(int eventId) async {
    final response = await _api.get('/events/$eventId/check-ins');
    return response.data is List ? response.data : [];
  }
}
