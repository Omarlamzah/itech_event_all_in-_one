import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../event_experience/config/app_brand.dart';
import '../../event_experience/data/event_api_client.dart';
import '../../event_experience/screens/home_screen.dart';
import '../../models/public_event.dart';

class EventExperienceScreen extends StatefulWidget {
  const EventExperienceScreen({required this.event, super.key});

  final PublicEvent event;

  @override
  State<EventExperienceScreen> createState() => _EventExperienceScreenState();
}

class _EventExperienceScreenState extends State<EventExperienceScreen> {
  late Future<AppBrand> _brand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _brand = EventApiClient(
      baseUrl: AppConfig.publicMobileBaseUrl,
    ).fetchBrand(widget.event.mobileCode!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBrand>(
      future: _brand,
      builder: (context, snapshot) {
        final brand = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(brand?.name ?? widget.event.name),
            backgroundColor: brand?.primaryColor ?? const Color(0xFF075E54),
            foregroundColor: Colors.white,
            centerTitle: false,
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? _EventLoading(event: widget.event)
              : snapshot.hasError
              ? _EventError(
                  error: snapshot.error!,
                  onRetry: () => setState(_load),
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: brand!.primaryColor,
                    ),
                  ),
                  child: HomeScreen(brand: brand),
                ),
        );
      },
    );
  }
}

class _EventLoading extends StatelessWidget {
  const _EventLoading({required this.event});
  final PublicEvent event;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A10231F),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Image.asset('assets/icon/app_icon.png'),
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text('Préparation de ${event.name}…'),
      ],
    ),
  );
}

class _EventError extends StatelessWidget {
  const _EventError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 58),
          const SizedBox(height: 14),
          const Text(
            'Le contenu de cet événement est indisponible',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
