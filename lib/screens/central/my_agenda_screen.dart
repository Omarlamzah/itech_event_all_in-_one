import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/mobile_account_service.dart';
import 'login_required.dart';

class MyAgendaScreen extends StatefulWidget {
  const MyAgendaScreen({super.key});

  @override
  State<MyAgendaScreen> createState() => _MyAgendaScreenState();
}

class _MyAgendaScreenState extends State<MyAgendaScreen> {
  final _service = MobileAccountService();
  Future<List<Map<String, dynamic>>>? _future;
  int? _loadedForUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<AuthProvider>().user?.id;
    if (id != null && id != _loadedForUser) {
      _loadedForUser = id;
      _future = _service.agenda();
    } else if (id == null) {
      _loadedForUser = null;
      _future = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAuthenticated) {
      return const SafeArea(
        child: LoginRequired(
          title: 'Construisez votre agenda',
          message:
              'Enregistrez vos sessions préférées et retrouvez votre programme personnel sur tous vos appareils.',
          icon: Icons.bookmark_added_rounded,
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 14, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROGRAMME PERSONNEL',
                        style: TextStyle(
                          color: Color(0xFF0B7A69),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mon agenda',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _future = _service.agenda()),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                final sessions = snapshot.data ?? const [];
                if (sessions.isEmpty) {
                  return const _EmptyAgenda();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 11),
                  itemBuilder: (context, index) =>
                      _AgendaTile(session: sessions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.session});
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(session['start_at']?.toString() ?? '');
    final event = session['event'] is Map
        ? Map<String, dynamic>.from(session['event'] as Map)
        : const <String, dynamic>{};
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE1E9E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 59,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F4EF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  start == null ? '--:--' : DateFormat('HH:mm').format(start),
                  style: const TextStyle(
                    color: Color(0xFF075E54),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (start != null)
                  Text(
                    DateFormat('dd MMM', 'fr_FR').format(start),
                    style: const TextStyle(
                      color: Color(0xFF62736D),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (session['title'] ?? 'Session').toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [session['speaker_name'], session['room']]
                      .where((value) => value?.toString().isNotEmpty == true)
                      .join(' • '),
                  style: const TextStyle(
                    color: Color(0xFF657670),
                    fontSize: 12,
                  ),
                ),
                if (event['name'] != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    event['name'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF0B7A69),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.bookmark_rounded, color: Color(0xFF0B7A69)),
        ],
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_rounded, size: 62, color: Color(0xFF7B8D87)),
          SizedBox(height: 13),
          Text(
            'Votre agenda est encore vide',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            'Ouvrez le programme d’un congrès et ajoutez les sessions qui vous intéressent.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF697A75)),
          ),
        ],
      ),
    ),
  );
}
