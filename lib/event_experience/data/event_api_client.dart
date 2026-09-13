import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_brand.dart';

class EventApiException implements Exception {
  const EventApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EventApiClient {
  EventApiClient({
    http.Client? client,
    String? baseUrl,
    SharedPreferencesAsync? preferences,
  }) : _client = client ?? http.Client(),
       _preferences = preferences,
       _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'API_URL',
             defaultValue:
                 'https://events.itechevent.com/api/public/api/public/mobile',
           );

  final http.Client _client;
  final SharedPreferencesAsync? _preferences;
  final String _baseUrl;

  Future<AppBrand> fetchBrand(String eventCode) async {
    Object? failure;
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/events/$eventCode/config'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final brand = _decodeBrand(response.body);
        await _writeCache(eventCode, response.body);
        return brand;
      }
      failure = EventApiException(
        'The event server returned ${response.statusCode}.',
      );
    } catch (error) {
      failure = error;
    }

    final cached = await _readCache(eventCode);
    if (cached != null) return _decodeBrand(cached);

    if (failure case final EventApiException exception) throw exception;
    throw const EventApiException(
      'Connexion indisponible et aucun programme hors connexion.',
    );
  }

  AppBrand _decodeBrand(String source) {
    final payload = jsonDecode(source) as Map<String, dynamic>;
    return AppBrand.fromApiJson(payload['data'] as Map<String, dynamic>);
  }

  Future<void> _writeCache(String eventCode, String source) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      await preferences.setString('event.$eventCode.config', source);
    } catch (_) {
      // The live response remains usable if local persistence is unavailable.
    }
  }

  Future<String?> _readCache(String eventCode) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      return await preferences.getString('event.$eventCode.config');
    } catch (_) {
      return null;
    }
  }
}
