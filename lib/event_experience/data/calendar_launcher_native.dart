import 'package:add_2_calendar/add_2_calendar.dart';

Future<bool> addNativeCalendarEvent({
  required String title,
  required String description,
  required String location,
  required DateTime startAt,
  required DateTime endAt,
  required String? eventUrl,
}) => Add2Calendar.addEvent2Cal(
  Event(
    title: title,
    description: description,
    location: location,
    startDate: startAt,
    endDate: endAt,
    timeZone: 'Africa/Casablanca',
    iosParams: IOSParams(reminder: const Duration(minutes: 30), url: eventUrl),
  ),
);
