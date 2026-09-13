import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/public_event.dart';
import '../../services/public_event_service.dart';
import 'event_navigation.dart';

class CentralHomeScreen extends StatefulWidget {
  const CentralHomeScreen({super.key});

  @override
  State<CentralHomeScreen> createState() => _CentralHomeScreenState();
}

class _CentralHomeScreenState extends State<CentralHomeScreen> {
  final _service = PublicEventService();
  final _search = TextEditingController();
  late Future<List<PublicEvent>> _future;
  String _filter = 'upcoming';

  @override
  void initState() {
    super.initState();
    _future = _service.getEvents();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.getEvents());
    await _future;
  }

  List<PublicEvent> _visible(List<PublicEvent> input) {
    final query = _search.text.trim().toLowerCase();
    final result = input.where((event) {
      final filterMatches = switch (_filter) {
        'past' => event.isPast,
        'all' => true,
        _ => !event.isPast,
      };
      if (!filterMatches) return false;
      if (query.isEmpty) return true;
      return '${event.name} ${event.fullName ?? ''} ${event.location ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    result.sort((a, b) {
      final aDate = a.startDate ?? DateTime(2100);
      final bDate = b.startDate ?? DateTime(2100);
      return _filter == 'past'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FAF8), Color(0xFFF5F7FB), Color(0xFFFFFFFF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: _CentralHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _DiscoveryHero(
                    onExplore: () {
                      _search.clear();
                      setState(() => _filter = 'upcoming');
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un congrès, une ville…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'À venir',
                        selected: _filter == 'upcoming',
                        onTap: () => setState(() => _filter = 'upcoming'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Tous',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Archives',
                        selected: _filter == 'past',
                        onTap: () => setState(() => _filter = 'past'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _filter == 'past'
                              ? 'Événements passés'
                              : 'Événements à découvrir',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 19,
                        color: Color(0xFF0B7A69),
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<PublicEvent>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: _LoadingCards());
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _LoadError(
                        error: snapshot.error!,
                        onRetry: _reload,
                      ),
                    );
                  }
                  final events = _visible(snapshot.data ?? const []);
                  if (events.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyEvents(),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.crossAxisExtent >= 720
                            ? 2
                            : 1;
                        if (columns == 1) {
                          return SliverList.separated(
                            itemCount: events.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) =>
                                _EventCard(
                                      event: events[index],
                                      onTap: () => openPublicEvent(
                                        context,
                                        events[index],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: (index * 55).ms)
                                    .slideY(begin: .04, end: 0),
                          );
                        }
                        return SliverGrid.builder(
                          itemCount: events.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.16,
                              ),
                          itemBuilder: (context, index) => _EventCard(
                            event: events[index],
                            onTap: () =>
                                openPublicEvent(context, events[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CentralHeader extends StatelessWidget {
  const _CentralHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 13),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18106359),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/icon/app_icon.png'),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'iTechEvent',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              Text(
                'Votre parcours événementiel',
                style: TextStyle(color: Color(0xFF6D7F7A), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
        ),
      ],
    ),
  );
}

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 190),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF063C49), Color(0xFF087A69), Color(0xFF38A58E)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x38066D60),
          blurRadius: 32,
          spreadRadius: -7,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned(
          right: -24,
          top: -35,
          child: Icon(
            Icons.public_rounded,
            size: 180,
            color: Color(0x16FFFFFF),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFFFD884),
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'LA PLATEFORME DES CONGRÈS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Tous vos événements.\nUne seule application.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 17),
            FilledButton.icon(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF075E54),
              ),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explorer les congrès'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0B7A69) : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: selected ? const Color(0xFF0B7A69) : const Color(0xFFE1E8E5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF53645F),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final PublicEvent event;
  final VoidCallback onTap;

  Color get _primary {
    final value = event.primaryColorHex?.replaceFirst('#', '');
    return Color(int.tryParse('FF$value', radix: 16) ?? 0xFF087A69);
  }

  @override
  Widget build(BuildContext context) {
    final start = event.startDate;
    final date = start == null
        ? 'Date à confirmer'
        : DateFormat('d MMM yyyy', 'fr_FR').format(start);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE4EBE8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14142622),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2.05,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    event.imageUrl == null
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primary, const Color(0xFF0A2931)],
                              ),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              size: 62,
                              color: Colors.white54,
                            ),
                          )
                        : Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: _primary,
                              child: const Icon(
                                Icons.event_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB800181C)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _StatusPill(event: event),
                    ),
                    if (event.hasEventApp)
                      const Positioned(
                        right: 14,
                        top: 14,
                        child: _GlassPill(
                          icon: Icons.phone_iphone_rounded,
                          label: 'App complète',
                        ),
                      ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Text(
                        event.fullName ?? event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 13, 15),
                child: Row(
                  children: [
                    _DateBlock(date: start),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 15,
                                color: Color(0xFF74837F),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  event.location ?? 'Lieu à confirmer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF74837F),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: _primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 52,
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5F1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          date == null ? '--' : DateFormat('dd').format(date!),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text(
          date == null
              ? 'DATE'
              : DateFormat('MMM', 'fr_FR').format(date!).toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF087A69),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.event});
  final PublicEvent event;

  @override
  Widget build(BuildContext context) {
    final label = event.isLive
        ? 'EN COURS'
        : event.isPast
        ? 'TERMINÉ'
        : 'À VENIR';
    final color = event.isLive
        ? const Color(0xFFE73553)
        : event.isPast
        ? const Color(0xFF667085)
        : const Color(0xFF0A806E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF075E54)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF075E54),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 250,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 54),
          const SizedBox(height: 12),
          const Text(
            'Connexion impossible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 58, color: Color(0xFF879792)),
          SizedBox(height: 12),
          Text(
            'Aucun événement trouvé',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
