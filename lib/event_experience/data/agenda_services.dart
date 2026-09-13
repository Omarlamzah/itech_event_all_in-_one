import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_brand.dart';
import '../../services/api_service.dart';
import 'calendar_launcher.dart';

class AgendaStore {
  AgendaStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  final SharedPreferencesAsync? _preferences;

  Future<Set<String>> loadFavorites(String eventCode) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      final values = await preferences.getStringList(
        'agenda.$eventCode.favorites',
      );
      return values?.toSet() ?? <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveFavorites(String eventCode, Set<String> favorites) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      final values = favorites.toList()..sort();
      await preferences.setStringList('agenda.$eventCode.favorites', values);
    } catch (_) {
      // Persistence is a convenience; the in-memory selection still works.
    }
  }

  Future<void> syncFavorite(AgendaItem item, bool saved) async {
    if (item.id == null) return;
    try {
      if (saved) {
        await ApiService().post('/mobile/my-agenda/${item.id}');
      } else {
        await ApiService().delete('/mobile/my-agenda/${item.id}');
      }
    } catch (_) {
      // Guests and offline users keep the same selection locally. Once they
      // authenticate, new changes are synchronized with their account.
    }
  }

  Future<bool> recordAndDetectAgendaChanges(
    String eventCode,
    List<AgendaItem> agenda,
  ) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      final sessions =
          agenda
              .map(
                (item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'start': item.startAt.toIso8601String(),
                  'end': item.endAt.toIso8601String(),
                  'speaker': item.speakerName,
                  'room': item.room,
                },
              )
              .toList()
            ..sort(
              (left, right) => '${left['id'] ?? left['start']}'.compareTo(
                '${right['id'] ?? right['start']}',
              ),
            );
      final snapshot = jsonEncode(sessions);
      final key = 'agenda.$eventCode.snapshot';
      final previous = await preferences.getString(key);
      await preferences.setString(key, snapshot);
      return previous != null && previous != snapshot;
    } catch (_) {
      return false;
    }
  }
}

class AgendaActions {
  const AgendaActions();

  Future<bool> addSessionToCalendar(AgendaItem item, AppBrand brand) =>
      _addToCalendar(
        title: '${brand.name} · ${item.title}',
        description: _sessionDescription(item, brand),
        location: item.room ?? brand.venueName ?? brand.location,
        startAt: item.startAt,
        endAt: item.endAt,
        eventUrl: brand.websiteUrl ?? brand.registrationUrl,
      );

  Future<bool> addDayToCalendar(
    DateTime date,
    List<AgendaItem> sessions,
    AppBrand brand,
  ) {
    final first = sessions.first;
    final last = sessions.last;
    return _addToCalendar(
      title: '${brand.name} · Programme du ${date.day}/${date.month}',
      description:
          '${sessions.length} sessions scientifiques\n${brand.fullName}',
      location: brand.venueName ?? first.room ?? brand.location,
      startAt: first.startAt,
      endAt: last.endAt,
      eventUrl: brand.websiteUrl ?? brand.registrationUrl,
    );
  }

  Future<bool> shareSession(AgendaItem item, AppBrand brand) {
    final speaker = item.speakerName?.trim();
    final room = item.room?.trim();
    final text = StringBuffer()
      ..writeln('📅 ${brand.name} · ${item.title}')
      ..writeln(
        '${_shortDate(item.startAt)} · ${_clock(item.startAt)}–${_clock(item.endAt)}',
      );
    if (speaker?.isNotEmpty ?? false) text.writeln('🎙️ $speaker');
    if (room?.isNotEmpty ?? false) text.writeln('📍 $room');
    final url = brand.websiteUrl ?? brand.registrationUrl;
    if (url?.trim().isNotEmpty ?? false) text.writeln(url);

    return launchUrl(
      Uri.https('wa.me', '/', {'text': text.toString().trim()}),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<bool> _addToCalendar({
    required String title,
    required String description,
    required String location,
    required DateTime startAt,
    required DateTime endAt,
    required String? eventUrl,
  }) async {
    final localStart = _asLocalWallClock(startAt);
    final localEnd = _asLocalWallClock(endAt);

    if (kIsWeb) {
      final parameters = <String, String>{
        'action': 'TEMPLATE',
        'text': title,
        'dates': '${_googleDate(localStart)}/${_googleDate(localEnd)}',
        'details': description,
        'location': location,
        'ctz': 'Africa/Casablanca',
      };
      return launchUrl(
        Uri.https('calendar.google.com', '/calendar/render', parameters),
        mode: LaunchMode.externalApplication,
      );
    }

    return addNativeCalendarEvent(
      title: title,
      description: description,
      location: location,
      startAt: localStart,
      endAt: localEnd,
      eventUrl: eventUrl,
    );
  }

  String _sessionDescription(AgendaItem item, AppBrand brand) {
    final lines = <String>[brand.fullName];
    if (item.speakerName?.trim().isNotEmpty ?? false) {
      lines.add('Intervenant : ${item.speakerName}');
    }
    if (item.description?.trim().isNotEmpty ?? false) {
      lines.add(item.description!.trim());
    }
    final url = brand.websiteUrl ?? brand.registrationUrl;
    if (url?.trim().isNotEmpty ?? false) lines.add(url!);
    return lines.join('\n');
  }
}

DateTime _asLocalWallClock(DateTime value) => DateTime(
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
  value.second,
);

String _googleDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}'
    'T${value.hour.toString().padLeft(2, '0')}'
    '${value.minute.toString().padLeft(2, '0')}'
    '${value.second.toString().padLeft(2, '0')}';

String _clock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
