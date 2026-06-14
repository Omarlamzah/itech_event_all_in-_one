import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../services/participant_service.dart';
import 'participant_form_screen.dart';

class ParticipantsScreen extends StatefulWidget {
  final Event event;
  const ParticipantsScreen({super.key, required this.event});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final _service = ParticipantService();
  List<Participant> _participants = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _service.getParticipants(widget.event.id, search: _search.isEmpty ? null : _search);
      setState(() { _participants = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'paye': return Colors.green;
      case 'pec': return Colors.blue;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.name} — Participants'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ParticipantFormScreen(event: widget.event)),
          );
          if (result == true) _load();
        },
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search participants...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                          _load();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() => _search = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _participants.isEmpty
                        ? const Center(child: Text('No participants found.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                              itemCount: _participants.length,
                              itemBuilder: (_, i) {
                                final p = _participants[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _paymentColor(p.paymentStatus).withOpacity(0.1),
                                      child: Text(
                                        p.nmComplet.isNotEmpty ? p.nmComplet[0].toUpperCase() : '?',
                                        style: TextStyle(color: _paymentColor(p.paymentStatus)),
                                      ),
                                    ),
                                    title: Text(p.nmComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (p.email != null) Text(p.email!, style: const TextStyle(fontSize: 12)),
                                        if (p.typeInscri != null) Text(p.typeInscri!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _paymentColor(p.paymentStatus).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            p.paymentStatus,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _paymentColor(p.paymentStatus),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (p.checkedIn)
                                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
