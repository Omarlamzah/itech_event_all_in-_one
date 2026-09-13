import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_brand.dart';
import '../data/agenda_services.dart';
import 'board_screen.dart';
import 'eposter_library_screen.dart';
import 'live_stream_screen.dart';
import 'media_library_screen.dart';

const _ink = Color(0xFF10231F);
const _muted = Color(0xFF667A74);
const _canvas = Color(0xFFF3F6F4);
const _line = Color(0xFFE0E8E4);

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.brand, super.key});
  final AppBrand brand;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final showMedia = widget.brand.supports(AppFeature.mediaLibrary);
    final pages = [
      _CongressHome(
        brand: widget.brand,
        openPage: (index) => setState(() => selectedIndex = index),
      ),
      _ProgramPage(brand: widget.brand),
      if (showMedia) MediaLibraryScreen(brand: widget.brand),
      _SpeakersPage(brand: widget.brand),
      _MorePage(brand: widget.brand),
    ];
    return Scaffold(
      backgroundColor: Color.lerp(widget.brand.primaryColor, Colors.black, .32),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ColoredBox(
            color: _canvas,
            child: SafeArea(
              bottom: false,
              child: IndexedStack(index: selectedIndex, children: pages),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ColoredBox(
            color: _canvas,
            child: SafeArea(
              top: false,
              child: _GlassNavigation(
                brand: widget.brand,
                selectedIndex: selectedIndex,
                onSelected: (index) => setState(() => selectedIndex = index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavigation extends StatelessWidget {
  const _GlassNavigation({
    required this.brand,
    required this.selectedIndex,
    required this.onSelected,
  });
  final AppBrand brand;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Accueil'),
      (Icons.calendar_month_rounded, 'Programme'),
      if (brand.supports(AppFeature.mediaLibrary))
        (Icons.video_library_rounded, 'Média'),
      (Icons.groups_2_rounded, 'Orateurs'),
      (Icons.grid_view_rounded, 'Plus'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        height: 68,
        shape: const LiquidRoundedSuperellipse(borderRadius: 25),
        settings: LiquidGlassSettings(
          glassColor: _ink.withValues(alpha: .94),
          thickness: 24,
          blur: 10,
          lightIntensity: .65,
          ambientStrength: .25,
          fresnelStrength: .7,
          glowIntensity: .35,
          shadowElevation: 4,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = selectedIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(19),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index].$1,
                        size: 21,
                        color: selected
                            ? brand.primaryColor
                            : Colors.white.withValues(alpha: .62),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index].$2,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected
                              ? _ink
                              : Colors.white.withValues(alpha: .62),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CongressHome extends StatelessWidget {
  const _CongressHome({required this.brand, required this.openPage});
  final AppBrand brand;
  final ValueChanged<int> openPage;

  @override
  Widget build(BuildContext context) {
    final actions = <_HomeAction>[
      if (brand.supports(AppFeature.program))
        _HomeAction(
          'Programme',
          'Sessions & horaires',
          Icons.calendar_month_rounded,
          () => openPage(1),
        ),
      if (brand.liveStream?.isAvailable ?? false)
        _HomeAction(
          'En direct',
          brand.liveStream!.isLive ? 'Live maintenant' : 'Voir la diffusion',
          Icons.live_tv_rounded,
          () => _openLiveStream(context, brand),
        ),
      if (brand.supports(AppFeature.mediaLibrary))
        _HomeAction(
          'Médiathèque',
          'Vidéos & conférences',
          Icons.video_library_rounded,
          () => openPage(2),
        ),
      if (brand.supports(AppFeature.eposters))
        _HomeAction(
          'E-Posters',
          'Communications affichées',
          Icons.auto_stories_rounded,
          () => _openEposters(context, brand),
        ),
      _HomeAction(
        'Informations',
        'Lieu, accès & contact',
        Icons.location_on_rounded,
        () => _showInformation(context, brand),
      ),
      if (brand.hasPresidentContent)
        _HomeAction(
          'Le président',
          'Lire son message',
          Icons.format_quote_rounded,
          () => _showPresident(context, brand),
        ),
      if (brand.boardMembers.isNotEmpty)
        _HomeAction(
          'Bureau',
          'Équipe dirigeante',
          Icons.account_balance_rounded,
          () => _openBoard(context, brand),
        ),
      if (brand.supports(AppFeature.speakers))
        _HomeAction(
          'Orateurs',
          'Experts invités',
          Icons.record_voice_over_rounded,
          () => openPage(brand.supports(AppFeature.mediaLibrary) ? 3 : 2),
        ),
      if (brand.supports(AppFeature.sponsors))
        _HomeAction(
          'Partenaires',
          'Ils nous accompagnent',
          Icons.handshake_rounded,
          () => _showSponsors(context, brand),
        ),
    ];
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _HomeHeader(brand: brand)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _HeroCard(
              brand: brand,
            ).animate().fadeIn(duration: 450.ms).slideY(begin: .035, end: 0),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 29, 20, 13),
          sliver: SliverToBoxAdapter(
            child: _SectionTitle(
              eyebrow: 'VOTRE EXPÉRIENCE',
              title: 'Tout le congrès, à portée de main',
              trailing: brand.year,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) =>
                _ActionTile(brand: brand, action: actions[index], index: index)
                    .animate()
                    .fadeIn(delay: (100 + index * 55).ms)
                    .slideY(begin: .07, end: 0),
          ),
        ),
        if (brand.agenda.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 29)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(
                eyebrow: 'À NE PAS MANQUER',
                title: 'Prochaine session',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _NextSessionCard(
                brand: brand,
                session: brand.agenda.first,
                onTap: () => openPage(1),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 15, 14, 13),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 49,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: brand.primaryColor.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            brand.logoAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BONJOUR',
                style: TextStyle(
                  color: _muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Bienvenue au congrès',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _line),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, color: brand.primaryColor),
              Positioned(
                right: 10,
                top: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA24A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    height: 390,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: brand.primaryColor,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: brand.primaryColor.withValues(alpha: .24),
          blurRadius: 34,
          spreadRadius: -8,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        _HeroImage(brand: brand),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .42, 1],
              colors: [
                Colors.black12,
                brand.primaryColor.withValues(alpha: .42),
                Color.lerp(
                  brand.primaryColor,
                  Colors.black,
                  .5,
                )!.withValues(alpha: .98),
              ],
            ),
          ),
        ),
        Positioned(
          left: -65,
          top: -95,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'ÉDITION ${brand.year}',
                  ),
                  const Spacer(),
                  const _HeroPill(
                    icon: Icons.circle,
                    label: 'OFFICIEL',
                    live: true,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                brand.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                brand.fullName.toUpperCase(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  height: .98,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.05,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      brand.venueName ?? brand.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _Countdown(brand: brand),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(brand.primaryColor, Colors.white, .12)!,
            Color.lerp(brand.primaryColor, Colors.black, .38)!,
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(.9, -.1),
        child: Icon(
          Icons.medical_information_outlined,
          size: 220,
          color: Colors.white.withValues(alpha: .07),
        ),
      ),
    );
    return brand.heroImageUrl == null
        ? fallback
        : Image.network(
            brand.heroImageUrl!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => fallback,
          );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.live = false});
  final IconData icon;
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: .22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: live ? 7 : 12,
          color: live ? const Color(0xFF65F4C1) : Colors.white,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.brand});
  final AppBrand brand;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.brand.startDate;
    final remaining = start?.difference(now) ?? Duration.zero;
    final active = remaining > Duration.zero;
    final values = active
        ? [
            remaining.inDays,
            remaining.inHours % 24,
            remaining.inMinutes % 60,
            remaining.inSeconds % 60,
          ]
        : [0, 0, 0, 0];
    const labels = ['Jours', 'Heures', 'Min', 'Sec'];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .19)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  active
                      ? 'LE RENDEZ-VOUS COMMENCE DANS'
                      : 'LE CONGRÈS EST OUVERT',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.05,
                  ),
                ),
              ),
              if (start != null)
                Text(
                  _shortDate(start),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 7),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          values[index].toString().padLeft(2, '0'),
                          key: ValueKey(values[index]),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: _muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -.55,
              ),
            ),
          ],
        ),
      ),
      if (trailing != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _line),
          ),
          child: Text(
            trailing!,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
    ],
  );
}

class _HomeAction {
  const _HomeAction(this.label, this.subtitle, this.icon, this.onTap);
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.brand,
    required this.action,
    required this.index,
  });
  final AppBrand brand;
  final _HomeAction action;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dark = index == 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          decoration: BoxDecoration(
            gradient: dark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brand.primaryColor,
                      Color.lerp(brand.primaryColor, Colors.black, .34)!,
                    ],
                  )
                : null,
            color: dark ? null : Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: dark ? null : Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: .13)
                            : brand.primaryColor.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        action.icon,
                        color: dark ? Colors.white : brand.primaryColor,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.north_east_rounded,
                      size: 18,
                      color: dark ? Colors.white60 : _muted,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dark ? Colors.white : _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dark ? Colors.white60 : _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.brand,
    required this.session,
    required this.onTap,
  });
  final AppBrand brand;
  final AgendaItem session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: brand.primaryColor,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                children: [
                  Text(
                    _time(session.startAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _time(session.endAt),
                    style: const TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (session.speakerName != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      session.speakerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: brand.primaryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (session.room != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      session.room!,
                      maxLines: 1,
                      style: const TextStyle(color: _muted, fontSize: 9.5),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.eyebrow,
    required this.brand,
    required this.icon,
  });
  final String title;
  final String eyebrow;
  final AppBrand brand;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 106,
    padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brand.primaryColor,
          Color.lerp(brand.primaryColor, Colors.black, .3)!,
        ],
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.45,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .13)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ],
    ),
  );
}

class _ProgramPage extends StatefulWidget {
  const _ProgramPage({required this.brand});
  final AppBrand brand;

  @override
  State<_ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<_ProgramPage> {
  final AgendaStore _agendaStore = AgendaStore();
  final AgendaActions _agendaActions = const AgendaActions();

  bool showPdf = false;
  bool showFavorites = false;
  bool scheduleUpdated = false;
  Set<String> favorites = <String>{};
  DateTime now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadAgendaState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant _ProgramPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brand.code != widget.brand.code ||
        oldWidget.brand.agenda != widget.brand.agenda) {
      _loadAgendaState();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadAgendaState() async {
    final loadedFavorites = await _agendaStore.loadFavorites(widget.brand.code);
    final changed = await _agendaStore.recordAndDetectAgendaChanges(
      widget.brand.code,
      widget.brand.agenda,
    );
    final validKeys = widget.brand.agenda
        .map((item) => item.storageKey)
        .toSet();
    loadedFavorites.removeWhere((key) => !validKeys.contains(key));
    if (!mounted) return;
    setState(() {
      favorites = loadedFavorites;
      scheduleUpdated = changed;
    });
  }

  void _toggleFavorite(AgendaItem item) {
    final adding = !favorites.contains(item.storageKey);
    AgendaItem? conflict;
    if (adding) {
      for (final selected in widget.brand.agenda.where(
        (candidate) => favorites.contains(candidate.storageKey),
      )) {
        if (_sessionsOverlap(item, selected)) {
          conflict = selected;
          break;
        }
      }
    }

    setState(() {
      if (adding) {
        favorites.add(item.storageKey);
      } else {
        favorites.remove(item.storageKey);
      }
    });
    unawaited(
      Future.wait([
        _agendaStore.saveFavorites(
          widget.brand.code,
          Set<String>.of(favorites),
        ),
        _agendaStore.syncFavorite(item, adding),
      ]),
    );

    final message = conflict != null
        ? 'Attention : chevauchement avec « ${conflict.title} ».'
        : adding
        ? 'Session ajoutée à Mon agenda.'
        : 'Session retirée de Mon agenda.';
    _showAgendaMessage(message, warning: conflict != null);
  }

  Future<void> _addSessionToCalendar(AgendaItem item) async {
    await _runAgendaAction(
      () => _agendaActions.addSessionToCalendar(item, widget.brand),
      successMessage: 'Session envoyée vers votre calendrier.',
    );
  }

  Future<void> _addDayToCalendar(
    DateTime date,
    List<AgendaItem> sessions,
  ) async {
    await _runAgendaAction(
      () => _agendaActions.addDayToCalendar(date, sessions, widget.brand),
      successMessage: 'Programme de la journée envoyé au calendrier.',
    );
  }

  Future<void> _shareSession(AgendaItem item) async {
    await _runAgendaAction(
      () => _agendaActions.shareSession(item, widget.brand),
      successMessage: 'WhatsApp ouvert.',
    );
  }

  Future<void> _runAgendaAction(
    Future<bool> Function() action, {
    required String successMessage,
  }) async {
    try {
      final success = await action();
      if (!mounted) return;
      _showAgendaMessage(
        success ? successMessage : 'Action annulée.',
        warning: !success,
      );
    } catch (_) {
      if (mounted) {
        _showAgendaMessage(
          'Cette action est indisponible sur cet appareil.',
          warning: true,
        );
      }
    }
  }

  void _showAgendaMessage(String message, {bool warning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: warning
              ? const Color(0xFF8A4A14)
              : widget.brand.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    final pdfUrl = brand.programPdfUrl;
    final hasAgenda = brand.agenda.isNotEmpty;
    return Column(
      children: [
        _ProgramHero(brand: brand),
        if (hasAgenda && pdfUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 5),
            child: _ViewSwitch(
              brand: brand,
              showPdf: showPdf,
              onChanged: (value) => setState(() => showPdf = value),
            ),
          ),
        Expanded(
          child: hasAgenda && !showPdf
              ? _AgendaList(
                  brand: brand,
                  now: now,
                  favorites: favorites,
                  showFavorites: showFavorites,
                  scheduleUpdated: scheduleUpdated,
                  onShowFavoritesChanged: (value) =>
                      setState(() => showFavorites = value),
                  onDismissUpdate: () =>
                      setState(() => scheduleUpdated = false),
                  onToggleFavorite: _toggleFavorite,
                  onAddSessionToCalendar: _addSessionToCalendar,
                  onAddDayToCalendar: _addDayToCalendar,
                  onShareSession: _shareSession,
                )
              : pdfUrl != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: PdfViewer.uri(Uri.parse(pdfUrl)),
                )
              : _EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Programme à venir',
                  message:
                      'Le programme scientifique sera publié prochainement.',
                  brand: brand,
                ),
        ),
      ],
    );
  }
}

class _ProgramHero extends StatelessWidget {
  const _ProgramHero({required this.brand});

  final AppBrand brand;

  @override
  Widget build(BuildContext context) {
    final firstSession = brand.agenda.isEmpty ? null : brand.agenda.first;
    return Container(
      height: 183,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(21, 22, 20, 21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(brand.primaryColor, Colors.black, .36)!,
            brand.primaryColor,
            Color.lerp(brand.primaryColor, brand.secondaryColor, .15)!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: brand.primaryColor.withValues(alpha: .18),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            bottom: -53,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 175,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Positioned(
            top: -65,
            right: 20,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .07),
                  width: 24,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'AGENDA SCIENTIFIQUE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.7,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 45,
                    height: 45,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(brand.logoAsset, fit: BoxFit.contain),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Le programme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.9,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeroMetaPill(
                    icon: Icons.view_agenda_rounded,
                    label: '${brand.agenda.length} sessions',
                  ),
                  if (firstSession != null) ...[
                    const SizedBox(width: 8),
                    _HeroMetaPill(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${firstSession.startAt.day} ${_month(firstSession.startAt)}',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({
    required this.brand,
    required this.showPdf,
    required this.onChanged,
  });
  final AppBrand brand;
  final bool showPdf;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 51,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        _SwitchItem(
          label: 'Agenda',
          icon: Icons.view_agenda_rounded,
          selected: !showPdf,
          brand: brand,
          onTap: () => onChanged(false),
        ),
        _SwitchItem(
          label: 'Document PDF',
          icon: Icons.picture_as_pdf_rounded,
          selected: showPdf,
          brand: brand,
          onTap: () => onChanged(true),
        ),
      ],
    ),
  );
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.brand,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final AppBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? brand.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: brand.primaryColor.withValues(alpha: .2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : _muted),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.brand,
    required this.now,
    required this.favorites,
    required this.showFavorites,
    required this.scheduleUpdated,
    required this.onShowFavoritesChanged,
    required this.onDismissUpdate,
    required this.onToggleFavorite,
    required this.onAddSessionToCalendar,
    required this.onAddDayToCalendar,
    required this.onShareSession,
  });

  final AppBrand brand;
  final DateTime now;
  final Set<String> favorites;
  final bool showFavorites;
  final bool scheduleUpdated;
  final ValueChanged<bool> onShowFavoritesChanged;
  final VoidCallback onDismissUpdate;
  final ValueChanged<AgendaItem> onToggleFavorite;
  final ValueChanged<AgendaItem> onAddSessionToCalendar;
  final void Function(DateTime, List<AgendaItem>) onAddDayToCalendar;
  final ValueChanged<AgendaItem> onShareSession;

  @override
  Widget build(BuildContext context) {
    final visibleAgenda = showFavorites
        ? brand.agenda
              .where((item) => favorites.contains(item.storageKey))
              .toList()
        : brand.agenda;
    final groups = <DateTime, List<AgendaItem>>{};
    for (final item in visibleAgenda) {
      final date = DateTime(
        item.startAt.year,
        item.startAt.month,
        item.startAt.day,
      );
      groups.putIfAbsent(date, () => <AgendaItem>[]).add(item);
    }

    final children = <Widget>[
      _NowNextCard(brand: brand, now: now),
      if (scheduleUpdated)
        _ScheduleUpdateBanner(brand: brand, onDismiss: onDismissUpdate),
      _AgendaFilter(
        brand: brand,
        showFavorites: showFavorites,
        favoriteCount: favorites.length,
        onChanged: onShowFavoritesChanged,
      ),
      if (visibleAgenda.isEmpty) _FavoriteAgendaEmpty(brand: brand),
    ];
    var animationIndex = 0;
    for (final entry in groups.entries) {
      final sessions = entry.value;
      children.add(
        _AgendaDay(
          date: entry.key,
          count: sessions.length,
          startsAt: sessions.first.startAt,
          endsAt: sessions.last.endAt,
          brand: brand,
          onAddToCalendar: () => onAddDayToCalendar(entry.key, sessions),
        ),
      );
      for (var index = 0; index < sessions.length; index++) {
        children.add(
          _AgendaCard(
                item: sessions[index],
                brand: brand,
                isLast: index == sessions.length - 1,
                isFavorite: favorites.contains(sessions[index].storageKey),
                onToggleFavorite: () => onToggleFavorite(sessions[index]),
                onAddToCalendar: () => onAddSessionToCalendar(sessions[index]),
                onShare: () => onShareSession(sessions[index]),
              )
              .animate()
              .fadeIn(delay: (animationIndex * 32).ms, duration: 360.ms)
              .slideY(begin: .035, end: 0),
        );
        animationIndex++;
      }
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 28),
      children: children,
    );
  }
}

class _NowNextCard extends StatelessWidget {
  const _NowNextCard({required this.brand, required this.now});

  final AppBrand brand;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final currentTime = _agendaClock(now);
    AgendaItem? live;
    AgendaItem? next;
    for (final item in brand.agenda) {
      final start = _agendaClock(item.startAt);
      final end = _agendaClock(item.endAt);
      if (!currentTime.isBefore(start) && currentTime.isBefore(end)) {
        live ??= item;
      } else if (start.isAfter(currentTime) &&
          (next == null || start.isBefore(_agendaClock(next.startAt)))) {
        next = item;
      }
    }

    final item = live ?? next;
    final isLive = live != null;
    final status = isLive
        ? 'EN DIRECT'
        : item != null
        ? 'À SUIVRE'
        : 'PROGRAMME TERMINÉ';
    final subtitle = isLive
        ? 'Jusqu’à ${_time(item!.endAt)} · ${item.room ?? brand.location}'
        : item != null
        ? '${_countdown(currentTime, _agendaClock(item.startAt))} · ${_time(item.startAt)}'
        : 'Merci d’avoir participé à ${brand.name}';
    final accent = isLive ? const Color(0xFFE65B4F) : brand.primaryColor;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(brand.primaryColor, Colors.black, .28)!,
            Color.lerp(brand.primaryColor, Colors.black, .08)!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brand.primaryColor.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Icon(
              isLive ? Icons.graphic_eq_rounded : Icons.schedule_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLive) ...[
                      Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeOut(duration: 800.ms),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: isLive
                            ? const Color(0xFFFFB9B2)
                            : Colors.white70,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item?.title ?? brand.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.15,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 8.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleUpdateBanner extends StatelessWidget {
  const _ScheduleUpdateBanner({required this.brand, required this.onDismiss});

  final AppBrand brand;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.fromLTRB(12, 10, 7, 10),
    decoration: BoxDecoration(
      color: brand.secondaryColor.withValues(alpha: .38),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: brand.primaryColor.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: brand.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sync_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Programme mis à jour',
                style: TextStyle(
                  color: _ink,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Des horaires ou des salles ont été actualisés.',
                style: TextStyle(color: _muted, fontSize: 8.5),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDismiss,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 17, color: _muted),
        ),
      ],
    ),
  );
}

class _AgendaFilter extends StatelessWidget {
  const _AgendaFilter({
    required this.brand,
    required this.showFavorites,
    required this.favoriteCount,
    required this.onChanged,
  });

  final AppBrand brand;
  final bool showFavorites;
  final int favoriteCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      children: [
        _AgendaFilterChip(
          label: 'Toutes les sessions',
          icon: Icons.view_agenda_rounded,
          selected: !showFavorites,
          brand: brand,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 8),
        _AgendaFilterChip(
          label: 'Mon agenda ($favoriteCount)',
          icon: Icons.bookmark_rounded,
          selected: showFavorites,
          brand: brand,
          onTap: () => onChanged(true),
        ),
      ],
    ),
  );
}

class _AgendaFilterChip extends StatelessWidget {
  const _AgendaFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.brand,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final AppBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? brand.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: selected ? brand.primaryColor : _line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : _muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FavoriteAgendaEmpty extends StatelessWidget {
  const _FavoriteAgendaEmpty({required this.brand});

  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: brand.secondaryColor.withValues(alpha: .42),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bookmark_add_rounded,
            color: brand.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Créez votre agenda',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Touchez le marque-page d’une session pour la retrouver ici.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 9.5, height: 1.4),
        ),
      ],
    ),
  );
}

class _AgendaDay extends StatelessWidget {
  const _AgendaDay({
    required this.date,
    required this.count,
    required this.startsAt,
    required this.endsAt,
    required this.brand,
    required this.onAddToCalendar,
  });

  final DateTime date;
  final int count;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppBrand brand;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(0, 14, 0, 18),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brand.primaryColor,
                Color.lerp(brand.primaryColor, Colors.black, .24)!,
              ],
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _month(date).substring(0, 3).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weekday(date),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_time(startsAt)} — ${_time(endsAt)}  ·  $count sessions',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Ajouter la journée au calendrier',
          child: Material(
            color: brand.secondaryColor.withValues(alpha: .4),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: onAddToCalendar,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.event_available_rounded,
                size: 18,
                color: brand.primaryColor,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.item,
    required this.brand,
    required this.isLast,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
    required this.onShare,
  });

  final AgendaItem item;
  final AppBrand brand;
  final bool isLast;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCalendar;
  final VoidCallback onShare;

  Color get accent {
    final value = item.colorHex?.replaceFirst('#', '');
    if (value != null && value.length == 6) {
      final parsed = int.tryParse('FF$value', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return switch (item.type) {
      'keynote' => const Color(0xFF7553D6),
      'break' || 'lunch' => const Color(0xFFC9822C),
      'workshop' => const Color(0xFF168B78),
      _ => brand.primaryColor,
    };
  }

  IconData get icon => switch (item.type) {
    'keynote' => Icons.mic_rounded,
    'break' => Icons.coffee_rounded,
    'lunch' => Icons.restaurant_rounded,
    'workshop' => Icons.science_rounded,
    _ => Icons.forum_rounded,
  };

  String get label => switch (item.type) {
    'keynote' => 'TEMPS FORT',
    'break' => 'PAUSE',
    'lunch' => 'DÉJEUNER',
    'workshop' => 'ATELIER',
    _ => 'SESSION',
  };

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 49,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _time(item.startAt),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _time(item.endAt),
                style: const TextStyle(color: _muted, fontSize: 8.5),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 29,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                bottom: isLast ? 40 : -14,
                child: Container(
                  width: 2,
                  color: accent.withValues(alpha: .22),
                ),
              ),
              Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .18),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showDetails(context),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x07000000),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 11, color: accent),
                                const SizedBox(width: 5),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${item.endAt.difference(item.startAt).inMinutes} min',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _AgendaMiniAction(
                            tooltip: 'Ajouter au calendrier',
                            icon: Icons.event_available_rounded,
                            color: accent,
                            onTap: onAddToCalendar,
                          ),
                          _AgendaMiniAction(
                            tooltip: isFavorite
                                ? 'Retirer de Mon agenda'
                                : 'Ajouter à Mon agenda',
                            icon: isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isFavorite ? accent : _muted,
                            onTap: onToggleFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14.5,
                          height: 1.24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.16,
                        ),
                      ),
                      if (item.description?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 7),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 9.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (item.speakerName?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 11),
                        Container(
                          padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8F6),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: .11),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 15,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.speakerName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (item.speakerTitle?.trim().isNotEmpty ??
                                        false)
                                      Text(
                                        item.speakerTitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 7.5,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (item.room?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: accent,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.room!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF9AABA5),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(21, 12, 21, 28),
        decoration: const BoxDecoration(
          color: _canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_time(item.startAt)} — ${_time(item.endAt)}',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 23,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                if (item.description?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 13),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ],
                if (item.speakerName?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 18),
                  _AgendaDetailRow(
                    icon: Icons.person_rounded,
                    title: item.speakerName!,
                    subtitle: item.speakerTitle ?? 'Intervenant',
                    color: accent,
                  ),
                ],
                if (item.room?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  _AgendaDetailRow(
                    icon: Icons.location_on_rounded,
                    title: item.room!,
                    subtitle: 'Lieu de la session',
                    color: accent,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onAddToCalendar();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: brand.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(
                          Icons.event_available_rounded,
                          size: 17,
                        ),
                        label: const Text(
                          'Calendrier',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AgendaSheetAction(
                      icon: Icons.share_rounded,
                      tooltip: 'Partager sur WhatsApp',
                      color: const Color(0xFF168B63),
                      onTap: () {
                        Navigator.of(context).pop();
                        onShare();
                      },
                    ),
                    const SizedBox(width: 8),
                    _AgendaSheetAction(
                      icon: isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                      tooltip: isFavorite
                          ? 'Retirer de Mon agenda'
                          : 'Ajouter à Mon agenda',
                      color: accent,
                      onTap: () {
                        Navigator.of(context).pop();
                        onToggleFavorite();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaMiniAction extends StatelessWidget {
  const _AgendaMiniAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, color: color, size: 17),
      ),
    ),
  );
}

class _AgendaSheetAction extends StatelessWidget {
  const _AgendaSheetAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 46,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    ),
  );
}

class _AgendaDetailRow extends StatelessWidget {
  const _AgendaDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _line),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 8.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SpeakersPage extends StatelessWidget {
  const _SpeakersPage({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _PageHeader(
        title: 'Les orateurs',
        eyebrow: 'EXPERTISE & PARTAGE',
        brand: brand,
        icon: Icons.groups_2_rounded,
      ),
      Expanded(
        child: brand.speakers.isEmpty
            ? _EmptyState(
                icon: Icons.record_voice_over_outlined,
                title: 'Orateurs à venir',
                message: 'Les experts invités seront annoncés prochainement.',
                brand: brand,
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ..._speakerSection(brand, 'Orateurs nationaux', 'national'),
                  ..._speakerSection(
                    brand,
                    'Orateurs internationaux',
                    'international',
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
    ],
  );
}

List<Widget> _speakerSection(AppBrand brand, String title, String category) {
  final speakers = brand.speakers
      .where((speaker) => speaker.category == category)
      .toList();
  if (speakers.isEmpty) return const [];
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 13),
      sliver: SliverToBoxAdapter(
        child: _SectionTitle(
          eyebrow: '${speakers.length.toString().padLeft(2, '0')} PROFILS',
          title: title,
        ),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: speakers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .71,
        ),
        itemBuilder: (context, index) => _SpeakerCard(
          speaker: speakers[index],
          brand: brand,
          index: index,
        ).animate().fadeIn(delay: (index * 55).ms).slideY(begin: .05, end: 0),
      ),
    ),
  ];
}

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({
    required this.speaker,
    required this.brand,
    required this.index,
  });
  final EventSpeaker speaker;
  final AppBrand brand;
  final int index;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(23),
    child: InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: () => _showSpeaker(context, brand, speaker),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SpeakerPhoto(speaker: speaker, brand: brand),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x50001F18)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 29,
                      height: 29,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: TextStyle(
                          color: brand.primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speaker.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13.5,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [speaker.title, speaker.country]
                        .whereType<String>()
                        .where((value) => value.isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: brand.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SpeakerPhoto extends StatelessWidget {
  const _SpeakerPhoto({required this.speaker, required this.brand});
  final EventSpeaker speaker;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: brand.secondaryColor.withValues(alpha: .55),
      child: Center(
        child: Text(
          speaker.name.trim().isEmpty
              ? '?'
              : speaker.name.trim().substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: brand.primaryColor,
            fontSize: 44,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    return speaker.photoUrl == null
        ? fallback
        : Image.network(
            speaker.photoUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => fallback,
          );
  }
}

void _showSpeaker(BuildContext context, AppBrand brand, EventSpeaker speaker) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PremiumSheet(
      brand: brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 126,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: _SpeakerPhoto(speaker: speaker, brand: brand),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              speaker.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
          ),
          if ([speaker.title, speaker.country].whereType<String>().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Center(
                child: Text(
                  [
                    speaker.title,
                    speaker.country,
                  ].whereType<String>().join(' · '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: brand.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (speaker.bio != null && speaker.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
              ),
              child: Text(
                speaker.bio!,
                style: const TextStyle(color: _muted, height: 1.65),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

void _showPresident(BuildContext context, AppBrand brand) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: .94,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: _canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _PresidentHero(brand: brand)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MESSAGE OFFICIEL',
                      style: TextStyle(
                        color: brand.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Chères Consœurs,\nChers Confrères,',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 26,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.75,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(21, 24, 21, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: _line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -4,
                            top: 2,
                            child: Icon(
                              Icons.format_quote_rounded,
                              color: brand.secondaryColor.withValues(
                                alpha: .55,
                              ),
                              size: 72,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: brand.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                brand.presidentMessage ??
                                    'Le mot du président sera publié prochainement.',
                                style: const TextStyle(
                                  color: Color(0xFF334842),
                                  height: 1.72,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                brand.presidentName ?? 'Le Président',
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Président · ${brand.name}',
                                style: TextStyle(
                                  color: brand.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PresidentHero extends StatelessWidget {
  const _PresidentHero({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    height: 300,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brand.primaryColor,
          Color.lerp(brand.primaryColor, Colors.black, .4)!,
        ],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -58,
          top: -78,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .09)),
            ),
          ),
        ),
        Positioned(
          top: 15,
          right: 15,
          child: IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .14),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        Positioned(
          left: 20,
          top: 25,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(brand.logoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 9),
              const Text(
                'Mot du\nprésident',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  height: .98,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 27,
          bottom: 22,
          child: _PresidentPortrait(
            photoUrl: brand.presidentPhotoUrl,
            name: brand.presidentName,
            brand: brand,
            size: 158,
          ),
        ),
        Positioned(
          left: 20,
          right: 190,
          bottom: 25,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brand.presidentName ?? 'Le Président',
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'PRÉSIDENT DU CONGRÈS',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PresidentPortrait extends StatelessWidget {
  const _PresidentPortrait({
    required this.photoUrl,
    required this.name,
    required this.brand,
    this.size = 126,
  });
  final String? photoUrl;
  final String? name;
  final AppBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: brand.secondaryColor,
      child: Center(
        child: Text(
          (name?.trim().isNotEmpty ?? false)
              ? name!.trim().substring(0, 1).toUpperCase()
              : 'P',
          style: TextStyle(
            color: brand.primaryColor,
            fontSize: size * .34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white70, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 28,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

void _showInformation(BuildContext context, AppBrand brand) {
  final rows = [
    _DetailRow(Icons.calendar_month_rounded, 'Date', _eventDateRange(brand)),
    _DetailRow(Icons.location_on_rounded, 'Lieu', brand.location),
    if (brand.venueName != null)
      _DetailRow(Icons.apartment_rounded, 'Établissement', brand.venueName!),
    if (brand.specialty != null)
      _DetailRow(
        Icons.medical_services_rounded,
        'Spécialité',
        brand.specialty!,
      ),
    if (brand.expectedParticipants != null)
      _DetailRow(
        Icons.groups_2_rounded,
        'Participants attendus',
        '${brand.expectedParticipants}',
      ),
    if (brand.contactEmail != null)
      _DetailRow(Icons.alternate_email_rounded, 'E-mail', brand.contactEmail!),
    if (brand.contactPhone != null)
      _DetailRow(Icons.phone_rounded, 'Téléphone', brand.contactPhone!),
  ];
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PremiumSheet(
      brand: brand,
      title: 'Informations pratiques',
      eyebrow: 'PRÉPAREZ VOTRE VENUE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (brand.description != null) ...[
            Text(
              brand.description!,
              style: const TextStyle(color: _muted, height: 1.55, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
          ...rows.map((row) => _DetailCard(row: row, brand: brand)),
          if (brand.mapUrl != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openUrl(brand.mapUrl!),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Ouvrir l’itinéraire'),
                style: FilledButton.styleFrom(
                  backgroundColor: brand.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

void _showSponsors(BuildContext context, AppBrand brand) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PremiumSheet(
      brand: brand,
      title: 'Partenaires & sponsors',
      eyebrow: 'MERCI POUR LEUR CONFIANCE',
      child: brand.sponsors.isEmpty
          ? _EmptyState(
              icon: Icons.handshake_outlined,
              title: 'Partenaires à venir',
              message: 'Nos partenaires seront annoncés prochainement.',
              brand: brand,
              compact: true,
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brand.sponsors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) =>
                  _SponsorCard(sponsor: brand.sponsors[index], brand: brand),
            ),
    ),
  );
}

class _SponsorCard extends StatelessWidget {
  const _SponsorCard({required this.sponsor, required this.brand});
  final EventSponsor sponsor;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: sponsor.websiteUrl == null
          ? null
          : () => _openUrl(sponsor.websiteUrl!),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: sponsor.logoUrl == null
                  ? Icon(
                      Icons.handshake_rounded,
                      size: 42,
                      color: brand.primaryColor,
                    )
                  : Image.network(
                      sponsor.logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.handshake_rounded,
                        size: 42,
                        color: brand.primaryColor,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              sponsor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sponsor.level.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                color: brand.primaryColor,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: .9,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PremiumSheet extends StatelessWidget {
  const _PremiumSheet({
    required this.brand,
    required this.child,
    this.title,
    this.eyebrow,
  });
  final AppBrand brand;
  final Widget child;
  final String? title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .91,
    child: Container(
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7D1CD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null)
                            Text(
                              eyebrow!,
                              style: TextStyle(
                                color: brand.primaryColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.25,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            title!,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 27,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.75,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 17),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.row, required this.brand});
  final _DetailRow row;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: brand.primaryColor.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(row.icon, color: brand.primaryColor, size: 20),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label.toUpperCase(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                row.value,
                style: const TextStyle(
                  color: _ink,
                  height: 1.35,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailRow {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _MorePage extends StatelessWidget {
  const _MorePage({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) {
    final entries = <_MoreEntry>[
      _MoreEntry(
        Icons.info_rounded,
        'Informations pratiques',
        'Lieu, date, accès et contact',
        () => _showInformation(context, brand),
      ),
      if (brand.liveStream?.isAvailable ?? false)
        _MoreEntry(
          Icons.live_tv_rounded,
          brand.liveStream!.isLive ? 'En direct maintenant' : 'Diffusion vidéo',
          brand.liveStream!.title,
          () => _openLiveStream(context, brand),
        ),
      if (brand.hasPresidentContent)
        _MoreEntry(
          Icons.format_quote_rounded,
          'Mot du président',
          brand.presidentName ?? 'Message officiel',
          () => _showPresident(context, brand),
        ),
      if (brand.boardMembers.isNotEmpty)
        _MoreEntry(
          Icons.account_balance_rounded,
          'Bureau de l’AGPC',
          '${brand.boardMembers.length} membres',
          () => _openBoard(context, brand),
        ),
      if (brand.supports(AppFeature.eposters))
        _MoreEntry(
          Icons.auto_stories_rounded,
          'E-Posters',
          'Bibliothèque scientifique',
          () => _openEposters(context, brand),
        ),
      if (brand.supports(AppFeature.sponsors))
        _MoreEntry(
          Icons.handshake_rounded,
          'Partenaires & sponsors',
          '${brand.sponsors.length} partenaire${brand.sponsors.length > 1 ? 's' : ''}',
          () => _showSponsors(context, brand),
        ),
      if (brand.registrationUrl != null)
        _MoreEntry(
          Icons.how_to_reg_rounded,
          'Inscription',
          'Accéder au formulaire officiel',
          () => _openUrl(brand.registrationUrl!),
        ),
    ];
    return Column(
      children: [
        _PageHeader(
          title: 'Découvrir',
          eyebrow: 'LE CONGRÈS EN DÉTAIL',
          brand: brand,
          icon: Icons.explore_rounded,
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _EventIdentityCard(brand: brand),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: _SectionTitle(
                  eyebrow: 'RACCOURCIS',
                  title: 'Explorez davantage',
                ),
              ),
              const SizedBox(height: 13),
              ...entries.map((entry) => _MoreTile(entry: entry, brand: brand)),
              if (brand.contactEmail != null || brand.contactPhone != null) ...[
                const SizedBox(height: 18),
                _ContactCard(brand: brand),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

void _openBoard(BuildContext context, AppBrand brand) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => BoardScreen(brand: brand)));
}

void _openEposters(BuildContext context, AppBrand brand) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => EposterLibraryScreen(brand: brand)),
  );
}

void _openLiveStream(BuildContext context, AppBrand brand) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LiveStreamScreen(brand: brand)),
  );
}

class _EventIdentityCard extends StatelessWidget {
  const _EventIdentityCard({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brand.primaryColor,
          Color.lerp(brand.primaryColor, Colors.black, .36)!,
        ],
      ),
      borderRadius: BorderRadius.circular(27),
      boxShadow: [
        BoxShadow(
          color: brand.primaryColor.withValues(alpha: .2),
          blurRadius: 28,
          offset: const Offset(0, 13),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -8,
          top: -18,
          child: Text(
            brand.year.length >= 2 ? brand.year.substring(2) : brand.year,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .07),
              fontSize: 105,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 86,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Image.asset(
                    brand.logoAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Spacer(),
                const _HeroPill(
                  icon: Icons.verified_rounded,
                  label: 'OFFICIEL',
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              brand.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_eventDateRange(brand)}  ·  ${brand.location}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MoreEntry {
  const _MoreEntry(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.entry, required this.brand});
  final _MoreEntry entry;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: entry.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: brand.primaryColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(entry.icon, color: brand.primaryColor, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: brand.secondaryColor.withValues(alpha: .42),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: brand.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Besoin d’aide ?',
                style: TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                brand.contactEmail ?? brand.contactPhone ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.brand,
    this.compact = false,
  });
  final IconData icon;
  final String title;
  final String message;
  final AppBrand brand;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: brand.primaryColor.withValues(alpha: .09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: brand.primaryColor, size: 33),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.45, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

DateTime _agendaClock(DateTime value) => DateTime(
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
  value.second,
);

bool _sessionsOverlap(AgendaItem first, AgendaItem second) {
  final firstStart = _agendaClock(first.startAt);
  final firstEnd = _agendaClock(first.endAt);
  final secondStart = _agendaClock(second.startAt);
  final secondEnd = _agendaClock(second.endAt);
  return firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);
}

String _countdown(DateTime from, DateTime to) {
  final difference = to.difference(from);
  if (difference.inDays > 0) {
    return 'Dans ${difference.inDays} j';
  }
  if (difference.inHours > 0) {
    final minutes = difference.inMinutes.remainder(60);
    return minutes == 0
        ? 'Dans ${difference.inHours} h'
        : 'Dans ${difference.inHours} h $minutes min';
  }
  return 'Dans ${difference.inMinutes.clamp(1, 59)} min';
}

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_month(date).substring(0, 3).toUpperCase()} ${date.year}';

String _weekday(DateTime date) => const [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
][date.weekday - 1];

String _month(DateTime date) => const [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
][date.month - 1];

String _eventDateRange(AppBrand brand) {
  final start = brand.startDate;
  final end = brand.endDate;
  if (start == null) return 'Date à confirmer';
  if (end == null ||
      (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day)) {
    return '${start.day} ${_month(start)} ${start.year}';
  }
  if (start.month == end.month && start.year == end.year) {
    return '${start.day}–${end.day} ${_month(start)} ${start.year}';
  }
  return '${start.day} ${_month(start)} – ${end.day} ${_month(end)} ${end.year}';
}

Future<void> _openUrl(String value) async {
  final uri = Uri.tryParse(value);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
