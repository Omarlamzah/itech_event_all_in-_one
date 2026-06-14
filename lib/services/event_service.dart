import '../models/event.dart';
import 'api_service.dart';

class EventService {
  final ApiService _api = ApiService();

  Future<List<Event>> getEvents() async {
    final response = await _api.get('/events');
    final data = response.data;
    final list = data is List ? data : (data['data'] ?? []);
    return (list as List).map((e) => Event.fromJson(e)).toList();
  }

  Future<Event> getEvent(int id) async {
    final response = await _api.get('/events/$id');
    return Event.fromJson(response.data);
  }

  Future<Event> createEvent(Map<String, dynamic> data) async {
    final response = await _api.post('/events', data: data);
    return Event.fromJson(response.data);
  }

  Future<Event> updateEvent(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/events/$id', data: data);
    return Event.fromJson(response.data);
  }

  Future<void> deleteEvent(int id) async {
    await _api.delete('/events/$id');
  }

  Future<Map<String, dynamic>> getEventStats(int id) async {
    final response = await _api.get('/events/$id/stats');
    return Map<String, dynamic>.from(response.data);
  }
}
