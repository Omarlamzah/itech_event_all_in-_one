import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/public_event.dart';
import 'api_service.dart';

class PublicEventService {
  PublicEventService({ApiService? api}) : _api = api ?? ApiService();

  static const _cacheKey = 'itechevent.public_events.v1';
  final ApiService _api;

  Future<List<PublicEvent>> getEvents() async {
    Object? failure;
    try {
      final response = await _api.get('/public/events');
      final raw = response.data is List
          ? response.data as List<dynamic>
          : (response.data['data'] as List<dynamic>? ?? const []);
      final encoded = jsonEncode(raw);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_cacheKey, encoded);
      return raw
          .map(
            (item) => PublicEvent.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    } catch (error) {
      failure = error;
    }

    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getString(_cacheKey);
    if (cached != null) {
      final raw = jsonDecode(cached) as List<dynamic>;
      return raw
          .map(
            (item) => PublicEvent.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    }
    throw failure;
  }
}
