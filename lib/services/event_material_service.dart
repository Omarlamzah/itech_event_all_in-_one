import '../models/event_material.dart';
import 'api_service.dart';

class EventMaterialService {
  final _api = ApiService();

  Future<List<EventMaterial>> getItems(int eventId) async {
    final res = await _api.get('/events/$eventId/materials');
    return (res.data as List).map((e) => EventMaterial.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getStats(int eventId) async {
    final res = await _api.get('/events/$eventId/materials/stats');
    return Map<String, dynamic>.from(res.data);
  }

  Future<EventMaterial> assign(int eventId, Map<String, dynamic> data) async {
    final res = await _api.post('/events/$eventId/materials', data: data);
    return EventMaterial.fromJson(res.data);
  }

  Future<EventMaterial> update(int eventId, int itemId, Map<String, dynamic> data) async {
    final res = await _api.put('/events/$eventId/materials/$itemId', data: data);
    return EventMaterial.fromJson(res.data);
  }

  Future<void> remove(int eventId, int itemId) async {
    await _api.delete('/events/$eventId/materials/$itemId');
  }
}
