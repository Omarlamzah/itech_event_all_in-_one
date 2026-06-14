import '../models/dashboard_stats.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _api = ApiService();

  Future<DashboardStats> getStats() async {
    final response = await _api.get('/dashboard');
    return DashboardStats.fromJson(response.data);
  }
}
