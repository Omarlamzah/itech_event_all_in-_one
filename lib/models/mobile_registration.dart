class MobileRegistration {
  const MobileRegistration({
    required this.id,
    required this.eventId,
    required this.eventName,
    this.eventStartDate,
    this.eventEndDate,
    this.eventLocation,
    this.eventImageUrl,
    this.mobileCode,
    this.participantName,
    this.registrationType,
    this.pack,
    this.barcode,
    this.paymentStatus,
    this.registrationStatus,
    this.badgePrinted = false,
    this.checkedIn = false,
  });

  final int id;
  final int eventId;
  final String eventName;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;
  final String? eventLocation;
  final String? eventImageUrl;
  final String? mobileCode;
  final String? participantName;
  final String? registrationType;
  final String? pack;
  final String? barcode;
  final String? paymentStatus;
  final String? registrationStatus;
  final bool badgePrinted;
  final bool checkedIn;

  factory MobileRegistration.fromJson(Map<String, dynamic> json) =>
      MobileRegistration(
        id: _int(json['id']),
        eventId: _int(json['event_id']),
        eventName: (json['event_name'] ?? 'Événement').toString(),
        eventStartDate: DateTime.tryParse(
          json['event_start_date']?.toString() ?? '',
        ),
        eventEndDate: DateTime.tryParse(
          json['event_end_date']?.toString() ?? '',
        ),
        eventLocation: json['event_location']?.toString(),
        eventImageUrl: json['event_image_url']?.toString(),
        mobileCode: json['mobile_code']?.toString(),
        participantName: json['participant_name']?.toString(),
        registrationType: json['registration_type']?.toString(),
        pack: json['pack']?.toString(),
        barcode: json['barcode']?.toString(),
        paymentStatus: json['payment_status']?.toString(),
        registrationStatus: json['registration_status']?.toString(),
        badgePrinted: json['badge_printed'] == true,
        checkedIn: json['checked_in'] == true,
      );

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
