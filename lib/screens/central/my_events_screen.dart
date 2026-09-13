import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/mobile_registration.dart';
import '../../models/public_event.dart';
import '../../providers/auth_provider.dart';
import '../../services/mobile_account_service.dart';
import 'event_navigation.dart';
import 'login_required.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final _service = MobileAccountService();
  Future<List<MobileRegistration>>? _future;
  int? _loadedForUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().user?.id;
    if (userId != null && userId != _loadedForUser) {
      _loadedForUser = userId;
      _future = _service.registrations();
    }
    if (userId == null) {
      _loadedForUser = null;
      _future = null;
    }
  }

  void _reload() => setState(() => _future = _service.registrations());

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const SafeArea(
        child: LoginRequired(
          title: 'Vos congrès au même endroit',
          message:
              'Connectez-vous pour retrouver vos inscriptions, votre statut et vos badges QR.',
          icon: Icons.confirmation_number_rounded,
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 14, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MES INSCRIPTIONS',
                        style: TextStyle(
                          color: Color(0xFF0B7A69),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mes événements',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MobileRegistration>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(error: snapshot.error!, onRetry: _reload);
                }
                final registrations = snapshot.data ?? const [];
                if (registrations.isEmpty) {
                  return const _NoRegistrations();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    itemCount: registrations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _RegistrationCard(registration: registrations[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration});
  final MobileRegistration registration;

  PublicEvent get _event => PublicEvent(
    id: registration.eventId,
    name: registration.eventName,
    startDate: registration.eventStartDate,
    endDate: registration.eventEndDate,
    location: registration.eventLocation,
    imageUrl: registration.eventImageUrl,
    mobileCode: registration.mobileCode,
  );

  @override
  Widget build(BuildContext context) {
    final date = registration.eventStartDate == null
        ? 'Date à confirmer'
        : DateFormat(
            'd MMMM yyyy',
            'fr_FR',
          ).format(registration.eventStartDate!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E9E6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10102622),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F4EF),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFF087A69),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.eventName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date • ${registration.eventLocation ?? 'Lieu à confirmer'}',
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E7E79),
                      ),
                    ),
                  ],
                ),
              ),
              _PaymentBadge(status: registration.paymentStatus),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (registration.registrationType?.isNotEmpty == true)
                _InfoChip(
                  icon: Icons.category_rounded,
                  label: registration.registrationType!,
                ),
              if (registration.pack?.isNotEmpty == true)
                _InfoChip(
                  icon: Icons.inventory_2_rounded,
                  label: registration.pack!,
                ),
              if (registration.checkedIn)
                const _InfoChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Check-in effectué',
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              if (registration.mobileCode?.isNotEmpty == true)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => openPublicEvent(context, _event),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Ouvrir'),
                  ),
                ),
              if (registration.mobileCode?.isNotEmpty == true &&
                  registration.barcode?.isNotEmpty == true)
                const SizedBox(width: 9),
              if (registration.barcode?.isNotEmpty == true)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBadge(context, registration),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 19),
                    label: const Text('Mon badge'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showBadge(BuildContext context, MobileRegistration registration) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              registration.eventName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              registration.participantName ?? '',
              style: const TextStyle(color: Color(0xFF687973)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE1E9E6)),
              ),
              child: QrImageView(
                data: registration.barcode!,
                size: 220,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF063C49),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF075E54),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              registration.barcode!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Présentez ce QR code à l’accueil du congrès.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF687973)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final paid = status == 'paye' || status == 'pec';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFFE6F6ED) : const Color(0xFFFFF2DC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status == 'paye'
            ? 'PAYÉ'
            : status == 'pec'
            ? 'PEC'
            : 'EN ATTENTE',
        style: TextStyle(
          color: paid ? const Color(0xFF147A45) : const Color(0xFF9B5B00),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F6F4),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF087A69)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _NoRegistrations extends StatelessWidget {
  const _NoRegistrations();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 62,
            color: Color(0xFF7C8E88),
          ),
          SizedBox(height: 13),
          Text(
            'Aucune inscription liée à ce compte',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            'Inscrivez-vous avec le même email pour retrouver automatiquement votre événement ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6E7E79)),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 50),
        const SizedBox(height: 10),
        Text('$error', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}
