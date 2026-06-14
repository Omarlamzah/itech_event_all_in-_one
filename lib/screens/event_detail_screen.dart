import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/event.dart';
import 'agenda_screen.dart';
import 'checkin_screen.dart';
import 'event_attachments_screen.dart';
import 'event_materials_screen.dart';
import 'participants_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image banner
            if (event.eventImg != null)
              _buildImageBanner(event.eventImg!),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.location != null)
                            _InfoRow(icon: Icons.location_on, text: event.location!),
                          if (event.startDate != null)
                            _InfoRow(icon: Icons.calendar_today, text: '${event.startDate} → ${event.endDate ?? '?'}'),
                          if (event.participantsCount != null)
                            _InfoRow(icon: Icons.people, text: '${event.participantsCount} participants'),
                          if (event.description != null && event.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(event.description!, style: const TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.people, color: Colors.blue,
                    title: 'Participants', subtitle: 'Voir, ajouter et gérer les participants',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParticipantsScreen(event: event))),
                  ),
                  _ActionTile(
                    icon: Icons.qr_code_scanner, color: Colors.green,
                    title: 'Check-In', subtitle: 'Scanner les badges pour enregistrer les arrivées',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckInScreen(event: event))),
                  ),
                  _ActionTile(
                    icon: Icons.schedule, color: Colors.orange,
                    title: 'Agenda', subtitle: 'Voir les sessions et le programme',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaScreen(event: event))),
                  ),
                  _ActionTile(
                    icon: Icons.inventory_2, color: Colors.purple,
                    title: 'Matériel', subtitle: 'Assigner et gérer le matériel de l\'événement',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventMaterialsScreen(event: event))),
                  ),
                  _ActionTile(
                    icon: Icons.attach_file, color: Colors.teal,
                    title: 'Pièces jointes', subtitle: 'Fichiers partagés avec l\'équipe',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventAttachmentsScreen(event: event))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBanner(String imgPath) {
    final base = AppConfig.baseUrl.replaceAll('/api', '');
    final url = imgPath.startsWith('/storage/') || imgPath.startsWith('storage/')
        ? '$base${imgPath.startsWith('/') ? imgPath : '/$imgPath'}'
        : '$base/storage/$imgPath';
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              )),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
