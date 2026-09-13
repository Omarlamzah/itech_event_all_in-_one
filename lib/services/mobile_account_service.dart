import '../models/mobile_registration.dart';
import 'api_service.dart';

class MobileAccountService {
  MobileAccountService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<MobileRegistration>> registrations() async {
    final response = await _api.get('/mobile/my-events');
    final raw = response.data['data'] as List<dynamic>? ?? const [];
    return raw
        .map(
          (item) => MobileRegistration.fromJson(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> agenda() async {
    final response = await _api.get('/mobile/my-agenda');
    final raw = response.data['data'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
        .toList();
  }
}
