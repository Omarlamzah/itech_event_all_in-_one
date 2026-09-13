import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../models/public_event.dart';

class GenericEventScreen extends StatelessWidget {
  const GenericEventScreen({required this.event, super.key});
  final PublicEvent event;

  @override
  Widget build(BuildContext context) {
    final date = event.startDate == null
        ? 'Date à venir'
        : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(event.startDate!);
    final programUrl = event.programUrl?.isNotEmpty == true
        ? event.programUrl!
        : '${AppConfig.baseUrl.replaceFirst(RegExp(r'/$'), '')}/public/events/${event.id}/program';
    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: event.imageUrl == null
                  ? const ColoredBox(
                      color: Color(0xFFE3F2EF),
                      child: Icon(Icons.event_rounded, size: 70),
                    )
                  : Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE3F2EF),
                        child: Icon(Icons.event_rounded, size: 70),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            event.fullName ?? event.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _Info(icon: Icons.calendar_month_rounded, text: date),
          if (event.location?.isNotEmpty == true)
            _Info(icon: Icons.location_on_rounded, text: event.location!),
          if (event.description?.isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Text(
              event.description!,
              style: const TextStyle(height: 1.55, fontSize: 15),
            ),
          ],
          const SizedBox(height: 26),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ProgramPdfScreen(
                  title: event.programTitle ?? 'Programme officiel',
                  url: programUrl,
                ),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Voir le programme'),
          ),
          const SizedBox(height: 12),
          if (event.registrationUrl?.isNotEmpty == true)
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(event.registrationUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.how_to_reg_rounded),
              label: const Text("S'inscrire à l'événement"),
            ),
        ],
      ),
    );
  }
}

class _ProgramPdfScreen extends StatelessWidget {
  const _ProgramPdfScreen({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: 'Ouvrir dans le navigateur',
          onPressed: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded),
        ),
      ],
    ),
    body: PdfViewer.uri(Uri.parse(url)),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
