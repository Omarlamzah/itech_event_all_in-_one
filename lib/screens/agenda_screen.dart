import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/agenda_session.dart';
import '../services/agenda_service.dart';

class AgendaScreen extends StatefulWidget {
  final Event event;
  const AgendaScreen({super.key, required this.event});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _service = AgendaService();
  List<AgendaSession> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sessions = await _service.getSessions(widget.event.id);
      setState(() { _sessions = sessions; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  String _formatTime(String? dt) {
    if (dt == null) return '';
    try {
      final parsed = DateTime.parse(dt);
      return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agenda — ${widget.event.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _sessions.isEmpty
                      ? const Center(child: Text('No sessions scheduled.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _sessions.length,
                          itemBuilder: (_, i) {
                            final s = _sessions[i];
                            final typeColor = _parseColor(s.typeColor);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: typeColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (s.typeName.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: typeColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      s.typeName,
                                                      style: TextStyle(fontSize: 11, color: typeColor),
                                                    ),
                                                  ),
                                                const Spacer(),
                                                if (s.startAt != null)
                                                  Text(
                                                    '${_formatTime(s.startAt)} - ${_formatTime(s.endAt)}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            if (s.speaker != null && s.speaker!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.person, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(s.speaker!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                                ],
                                              ),
                                            ],
                                            if (s.room != null && s.room!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.room, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(s.room!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
