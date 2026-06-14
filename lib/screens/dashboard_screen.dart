import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = DashboardService();
  DashboardStats? _stats;
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
      final stats = await _service.getStats();
      setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overview',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            StatCard(
                              label: 'Total Events',
                              value: '${_stats!.totalEvents}',
                              icon: Icons.event,
                              color: Colors.blue,
                            ),
                            StatCard(
                              label: 'Total Participants',
                              value: '${_stats!.totalParticipants}',
                              icon: Icons.people,
                              color: Colors.purple,
                            ),
                            StatCard(
                              label: 'Paid',
                              value: '${_stats!.paye}',
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                            StatCard(
                              label: 'Unpaid',
                              value: '${_stats!.nonPaye}',
                              icon: Icons.cancel,
                              color: Colors.red,
                            ),
                            StatCard(
                              label: 'PEC',
                              value: '${_stats!.pec}',
                              icon: Icons.assignment,
                              color: Colors.orange,
                            ),
                            StatCard(
                              label: 'Badge Printed',
                              value: '${_stats!.badgePrinted}',
                              icon: Icons.badge,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Recent Events',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_stats!.recentEvents.isEmpty)
                          const Text('No events yet.', style: TextStyle(color: Colors.grey))
                        else
                          ...(_stats!.recentEvents.map((e) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.event)),
                                  title: Text(e.name),
                                  subtitle: Text(e.location ?? 'No location'),
                                  trailing: e.participantsCount != null
                                      ? Chip(
                                          label: Text('${e.participantsCount}'),
                                          avatar: const Icon(Icons.people, size: 16),
                                        )
                                      : null,
                                ),
                              ))),
                      ],
                    ),
                  ),
                ),
    );
  }
}
