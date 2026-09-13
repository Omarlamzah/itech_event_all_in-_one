import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_brand.dart';
import '../data/event_media_client.dart';
import 'media_video_player_screen.dart';

const _mediaInk = Color(0xFF10231F);
const _mediaMuted = Color(0xFF667A74);
const _mediaCanvas = Color(0xFFF3F6F4);
const _mediaLine = Color(0xFFE0E8E4);

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({required this.brand, super.key});

  final AppBrand brand;

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  final _client = EventMediaClient();
  final _searchController = TextEditingController();
  EventMediaLibrary? _library;
  Object? _error;
  bool _loading = true;
  String? _selectedCategory;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final library = await _client.fetchLibrary(widget.brand.code);
      if (!mounted) return;
      setState(() => _library = library);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<EventMediaItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return (_library?.items ?? const []).where((item) {
      final categoryMatches =
          _selectedCategory == null || item.category == _selectedCategory;
      final queryMatches =
          query.isEmpty ||
          '${item.title} ${item.description ?? ''}'.toLowerCase().contains(
            query,
          );
      return categoryMatches && queryMatches;
    }).toList();
  }

  String _categoryLabel(String key) =>
      _library?.categories
          .where((category) => category.key == key)
          .map((category) => category.label)
          .firstOrNull ??
      key;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _mediaCanvas,
      child: RefreshIndicator(
        color: widget.brand.primaryColor,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _MediaHeader(brand: widget.brand)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 17, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une conférence…',
                    hintStyle: const TextStyle(
                      color: _mediaMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 19),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: _mediaLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: _mediaLine),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: widget.brand.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_library != null)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 65,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
                    children: [
                      _CategoryChip(
                        label: 'Tout',
                        selected: _selectedCategory == null,
                        brand: widget.brand,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      ..._library!.categories.map(
                        (category) => _CategoryChip(
                          label: category.label,
                          selected: _selectedCategory == category.key,
                          brand: widget.brand,
                          onTap: () =>
                              setState(() => _selectedCategory = category.key),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: widget.brand.primaryColor,
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _MediaMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Connexion impossible',
                  message:
                      'La médiathèque n’est pas disponible pour le moment.',
                  brand: widget.brand,
                  actionLabel: 'Réessayer',
                  onAction: _load,
                ),
              )
            else if (_visibleItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _MediaMessage(
                  icon: Icons.video_library_outlined,
                  title: _library?.items.isEmpty ?? true
                      ? 'Médiathèque à venir'
                      : 'Aucun résultat',
                  message: _library?.items.isEmpty ?? true
                      ? 'Les premières conférences seront publiées prochainement.'
                      : 'Essayez une autre recherche ou une autre catégorie.',
                  brand: widget.brand,
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 7, 20, 13),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAVOIR & TRANSMISSION',
                              style: TextStyle(
                                color: widget.brand.primaryColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.45,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'À regarder maintenant',
                              style: TextStyle(
                                color: _mediaInk,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.brand.secondaryColor.withValues(
                            alpha: .5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_visibleItems.length}',
                          style: TextStyle(
                            color: widget.brand.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
                sliver: SliverList.separated(
                  itemCount: _visibleItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 13),
                  itemBuilder: (context, index) =>
                      _MediaCard(
                            item: _visibleItems[index],
                            categoryLabel: _categoryLabel(
                              _visibleItems[index].category,
                            ),
                            brand: widget.brand,
                            onTap: () => _open(_visibleItems[index]),
                          )
                          .animate()
                          .fadeIn(delay: (index.clamp(0, 6) * 55).ms)
                          .slideY(begin: .04, end: 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(EventMediaItem item) async {
    if (item.mediaType == 'video' && item.youtubeVideoId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MediaVideoPlayerScreen(
            item: item,
            categoryLabel: _categoryLabel(item.category),
            brand: widget.brand,
          ),
        ),
      );
      return;
    }

    final target = item.targetUrl;
    if (target == null) return;
    final uri = Uri.tryParse(target);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir ce contenu.')),
      );
    }
  }
}

class _MediaHeader extends StatelessWidget {
  const _MediaHeader({required this.brand});

  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    height: 155,
    padding: const EdgeInsets.fromLTRB(20, 17, 20, 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(brand.primaryColor, Colors.black, .25)!,
          brand.primaryColor,
        ],
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(31)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          top: -55,
          child: Icon(
            Icons.play_circle_outline_rounded,
            size: 170,
            color: Colors.white.withValues(alpha: .07),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(brand.logoAsset, fit: BoxFit.contain),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'CONTENU OFFICIEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'MÉDIATHÈQUE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'La science, en replay.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.brand,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? brand.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? brand.primaryColor : _mediaLine),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _mediaMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    required this.categoryLabel,
    required this.brand,
    required this.onTap,
  });

  final EventMediaItem item;
  final String categoryLabel;
  final AppBrand brand;
  final VoidCallback onTap;

  IconData get _icon => switch (item.mediaType) {
    'video' => Icons.play_arrow_rounded,
    'document' => Icons.picture_as_pdf_rounded,
    _ => Icons.open_in_new_rounded,
  };

  String get _typeLabel => switch (item.mediaType) {
    'video' => 'VIDÉO',
    'document' => 'DOCUMENT',
    _ => 'LIEN',
  };

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: item.targetUrl == null ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _mediaLine),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MediaCover(item: item, brand: brand),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 12),
                        ],
                      ),
                      child: Icon(_icon, color: brand.primaryColor, size: 25),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    bottom: 8,
                    child: Text(
                      _typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: brand.primaryColor,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .85,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mediaInk,
                        height: 1.18,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.publishedOn != null) ...[
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: _mediaMuted,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _date(item.publishedOn!),
                            style: const TextStyle(
                              color: _mediaMuted,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: brand.primaryColor,
                          size: 17,
                        ),
                      ],
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

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _MediaCover extends StatelessWidget {
  const _MediaCover({required this.item, required this.brand});

  final EventMediaItem item;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.primaryColor,
            Color.lerp(brand.primaryColor, Colors.black, .5)!,
          ],
        ),
      ),
      child: Icon(
        Icons.video_library_outlined,
        color: Colors.white.withValues(alpha: .14),
        size: 65,
      ),
    );
    final cover = item.coverUrl;
    return cover == null
        ? fallback
        : Image.network(
            cover,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => fallback,
          );
  }
}

class _MediaMessage extends StatelessWidget {
  const _MediaMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.brand,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final AppBrand brand;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: brand.secondaryColor.withValues(alpha: .45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: brand.primaryColor, size: 32),
        ),
        const SizedBox(height: 17),
        Text(
          title,
          style: const TextStyle(
            color: _mediaInk,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _mediaMuted, height: 1.5, fontSize: 12),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAction,
            style: FilledButton.styleFrom(backgroundColor: brand.primaryColor),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}
