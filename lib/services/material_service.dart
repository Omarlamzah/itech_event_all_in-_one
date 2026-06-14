import '../models/material_item.dart';
import 'api_service.dart';

class MaterialService {
  final _api = ApiService();

  Future<List<MaterialItem>> getMaterials() async {
    final res = await _api.get('/materials');
    return (res.data as List).map((e) => MaterialItem.fromJson(e)).toList();
  }

  Future<MaterialItem> create(Map<String, dynamic> data) async {
    final res = await _api.post('/materials', data: data);
    return MaterialItem.fromJson(res.data);
  }

  Future<MaterialItem> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/materials/$id', data: data);
    return MaterialItem.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _api.delete('/materials/$id');
  }
}
