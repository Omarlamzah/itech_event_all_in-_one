import 'event.dart';

class DashboardStats {
  final int totalEvents;
  final int totalParticipants;
  final int badgePrinted;
  final int badgePending;
  final int paye;
  final int nonPaye;
  final int pec;
  final int voucherSent;
  final List<Event> recentEvents;

  DashboardStats({
    required this.totalEvents,
    required this.totalParticipants,
    required this.badgePrinted,
    required this.badgePending,
    required this.paye,
    required this.nonPaye,
    required this.pec,
    required this.voucherSent,
    required this.recentEvents,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEvents: json['total_events'] ?? 0,
      totalParticipants: json['total_participants'] ?? 0,
      badgePrinted: json['badge_printed'] ?? 0,
      badgePending: json['badge_pending'] ?? 0,
      paye: json['paye'] ?? 0,
      nonPaye: json['non_paye'] ?? 0,
      pec: json['pec'] ?? 0,
      voucherSent: json['voucher_sent'] ?? 0,
      recentEvents: (json['recent_events'] as List<dynamic>? ?? [])
          .map((e) => Event.fromJson(e))
          .toList(),
    );
  }
}
