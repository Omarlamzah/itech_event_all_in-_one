import 'package:flutter/material.dart' show Color, Colors;

class Participant {
  final int id;
  final int eventId;
  final String nmComplet;
  final String? ville;
  final String? email;
  final String? tele;
  final String? laboratoire;
  final String? typeInscri;
  final String? codebare;
  final String badge;
  final String paymentStatus;
  final bool invoiceStatus;
  final String? status;
  final bool checkedIn;
  final String? checkedInAt;

  Participant({
    required this.id,
    required this.eventId,
    required this.nmComplet,
    this.ville,
    this.email,
    this.tele,
    this.laboratoire,
    this.typeInscri,
    this.codebare,
    required this.badge,
    required this.paymentStatus,
    required this.invoiceStatus,
    this.status,
    required this.checkedIn,
    this.checkedInAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      eventId: json['event_id'],
      nmComplet: json['NmComplet'] ?? '',
      ville: json['ville'],
      email: json['email'],
      tele: json['tele'],
      laboratoire: json['aboratoire'],
      typeInscri: json['typeInscri'],
      codebare: json['codebare'],
      badge: json['badge'] ?? 'non',
      paymentStatus: json['paymentstatus'] ?? 'non paye',
      invoiceStatus: json['invoice_status'] == true || json['invoice_status'] == 1,
      status: json['status'],
      checkedIn: json['checked_in'] == true || json['checked_in'] == 1,
      checkedInAt: json['checked_in_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'NmComplet': nmComplet,
        'ville': ville,
        'email': email,
        'tele': tele,
        'aboratoire': laboratoire,
        'typeInscri': typeInscri,
        'paymentstatus': paymentStatus,
        'status': status,
      };

  Color get paymentColor {
    switch (paymentStatus) {
      case 'paye':
        return Colors.green;
      case 'pec':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
}
