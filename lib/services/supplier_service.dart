import '../models/supplier.dart';
import 'api_service.dart';

class SupplierService {
  final _api = ApiService();

  Future<List<Supplier>> getSuppliers() async {
    final res = await _api.get('/suppliers');
    return (res.data as List).map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> create(Map<String, dynamic> data) async {
    final res = await _api.post('/suppliers', data: data);
    return Supplier.fromJson(res.data);
  }

  Future<Supplier> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/suppliers/$id', data: data);
    return Supplier.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _api.delete('/suppliers/$id');
  }
}
