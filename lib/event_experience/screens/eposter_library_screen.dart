import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_brand.dart';
import '../data/event_eposter_client.dart';

const _posterInk = Color(0xFF111F2F);
const _posterMuted = Color(0xFF6B7687);
const _posterCanvas = Color(0xFFF4F5F9);
const _posterLine = Color(0xFFE1E4EC);

class EposterLibraryScreen extends StatefulWidget {
  const EposterLibraryScreen({required this.brand, super.key});

  final AppBrand brand;

  @override
  State<EposterLibraryScreen> createState() => _EposterLibraryScreenState();
}

class _EposterLibraryScreenState extends State<EposterLibraryScreen> {
  final _client = EventEposterClient();
  final _searchController = TextEditingController();
  EventEposterLibrary? _library;
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

  List<EventEposter> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return (_library?.items ?? const []).where((poster) {
      final categoryMatches =
          _selectedCategory == null || poster.category == _selectedCategory;
      final searchable =
          '${poster.displayNumber} ${poster.title} ${poster.authors ?? ''} ${poster.keywords ?? ''}'
              .toLowerCase();
      return categoryMatches && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(widget.brand.primaryColor, Colors.black, .54),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ColoredBox(
            color: _posterCanvas,
            child: SafeArea(
              child: RefreshIndicator(
                color: widget.brand.primaryColor,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _EposterHeader(
                        brand: widget.brand,
                        total: _library?.items.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 17, 16, 0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Titre, auteur ou numéro du poster…',
                            hintStyle: const TextStyle(
                              color: _posterMuted,
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
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                    ),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: _posterLine),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: _posterLine),
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
                    if (_library != null && _library!.categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 66,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
                            children: [
                              _PosterCategoryChip(
                                label: 'Tous',
                                selected: _selectedCategory == null,
                                brand: widget.brand,
                                onTap: () =>
                                    setState(() => _selectedCategory = null),
                              ),
                              ..._library!.categories.map(
                                (category) => _PosterCategoryChip(
                                  label: category.label,
                                  selected: _selectedCategory == category.key,
                                  brand: widget.brand,
                                  onTap: () => setState(
                                    () => _selectedCategory = category.key,
                                  ),
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
                        child: _PosterMessage(
                          icon: Icons.cloud_off_rounded,
                          title: 'Connexion impossible',
                          message:
                              'La bibliothèque des e-posters est momentanément indisponible.',
                          brand: widget.brand,
                          actionLabel: 'Réessayer',
                          onAction: _load,
                        ),
                      )
                    else if (_visibleItems.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PosterMessage(
                          icon: Icons.description_outlined,
                          title: _library?.items.isEmpty ?? true
                              ? 'E-posters à venir'
                              : 'Aucun résultat',
                          message: _library?.items.isEmpty ?? true
                              ? 'Les communications affichées seront publiées prochainement.'
                              : 'Essayez un autre auteur, titre ou catégorie.',
                          brand: widget.brand,
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 7, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'COMMUNICATIONS AFFICHÉES',
                                      style: TextStyle(
                                        color: widget.brand.primaryColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Explorer les e-posters',
                                      style: TextStyle(
                                        color: _posterInk,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -.5,
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
                                  color: widget.brand.primaryColor.withValues(
                                    alpha: .09,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_visibleItems.length}',
                                  style: TextStyle(
                                    color: widget.brand.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        sliver: SliverList.separated(
                          itemCount: _visibleItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _EposterCard(
                                    poster: _visibleItems[index],
                                    brand: widget.brand,
                                    onComments: () => _showPosterComments(
                                      context,
                                      _visibleItems[index],
                                      widget.brand,
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => EposterReaderScreen(
                                          brand: widget.brand,
                                          posters: _visibleItems,
                                          initialIndex: index,
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: (index.clamp(0, 7) * 45).ms)
                                  .slideY(begin: .045, end: 0),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EposterHeader extends StatelessWidget {
  const _EposterHeader({required this.brand, required this.total});

  final AppBrand brand;
  final int? total;

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    padding: const EdgeInsets.fromLTRB(18, 13, 18, 22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(brand.primaryColor, Colors.black, .5)!,
          brand.primaryColor,
          Color.lerp(brand.primaryColor, const Color(0xFF7541D8), .45)!,
        ],
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          bottom: -51,
          child: Icon(
            Icons.auto_stories_rounded,
            size: 190,
            color: Colors.white.withValues(alpha: .07),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .14),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 105),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Image.asset(brand.logoAsset, fit: BoxFit.contain),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'BIBLIOTHÈQUE SCIENTIFIQUE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.65,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'E-Posters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                if (total != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                      ),
                    ),
                    child: Text(
                      '$total poster${total == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _EposterCard extends StatelessWidget {
  const _EposterCard({
    required this.poster,
    required this.brand,
    required this.onTap,
    required this.onComments,
  });

  final EventEposter poster;
  final AppBrand brand;
  final VoidCallback onTap;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _posterLine),
          boxShadow: [
            BoxShadow(
              color: _posterInk.withValues(alpha: .045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'eposter-cover-${poster.id}',
              child: Container(
                width: 112,
                height: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(brand.primaryColor, Colors.black, .3)!,
                      Color.lerp(
                        brand.primaryColor,
                        const Color(0xFF8151E8),
                        .55,
                      )!,
                    ],
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(23),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (poster.coverUrl != null)
                      Image.network(
                        poster.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _PosterCoverFallback(),
                      )
                    else
                      const _PosterCoverFallback(),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          poster.displayNumber,
                          style: TextStyle(
                            color: brand.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            poster.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: brand.primaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .85,
                            ),
                          ),
                        ),
                        if (poster.award?.trim().isNotEmpty == true)
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.amber.shade700,
                            size: 17,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      poster.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _posterInk,
                        fontSize: 14,
                        height: 1.24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.18,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            poster.authors?.trim().isNotEmpty == true
                                ? poster.authors!
                                : 'Communication scientifique',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _posterMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: brand.primaryColor.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: onComments,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_comment_rounded,
                                    color: brand.primaryColor,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Commenter',
                                    style: TextStyle(
                                      color: brand.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (poster.commentsCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '· ${poster.commentsCount}',
                                      style: TextStyle(
                                        color: brand.primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
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
}

class _PosterCoverFallback extends StatelessWidget {
  const _PosterCoverFallback();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        right: -28,
        bottom: -20,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .07),
          ),
        ),
      ),
      const Center(
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: Colors.white70,
          size: 43,
        ),
      ),
    ],
  );
}

class _PosterCategoryChip extends StatelessWidget {
  const _PosterCategoryChip({
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
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: brand.primaryColor,
      side: BorderSide(color: selected ? brand.primaryColor : _posterLine),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _posterMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _PosterMessage extends StatelessWidget {
  const _PosterMessage({
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
    padding: const EdgeInsets.all(34),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: brand.primaryColor.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: brand.primaryColor, size: 34),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _posterInk,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _posterMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAction,
            style: FilledButton.styleFrom(backgroundColor: brand.primaryColor),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}

class EposterReaderScreen extends StatefulWidget {
  const EposterReaderScreen({
    required this.brand,
    required this.posters,
    required this.initialIndex,
    super.key,
  });

  final AppBrand brand;
  final List<EventEposter> posters;
  final int initialIndex;

  @override
  State<EposterReaderScreen> createState() => _EposterReaderScreenState();
}

class _EposterReaderScreenState extends State<EposterReaderScreen> {
  late int _index;

  EventEposter get poster => widget.posters[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.posters.length) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF08101D),
    body: SafeArea(
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.brand.primaryColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      poster.displayNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poster.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_index + 1} / ${widget.posters.length}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _index == 0 ? null : () => _move(-1),
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    onPressed: _index == widget.posters.length - 1
                        ? null
                        : () => _move(1),
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  IconButton(
                    onPressed: () =>
                        _showPosterDetails(context, poster, widget.brand),
                    color: Colors.white,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _showPosterComments(context, poster, widget.brand),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.brand.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      shadowColor: widget.brand.primaryColor.withValues(
                        alpha: .45,
                      ),
                    ),
                    icon: const Icon(Icons.add_comment_rounded, size: 20),
                    label: Text(
                      poster.commentsCount > 0
                          ? 'Ajouter un commentaire  ·  ${poster.commentsCount}'
                          : 'Ajouter un commentaire',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: ColoredBox(
                    color: const Color(0xFFE7E9EF),
                    child: PdfViewer.uri(
                      Uri.parse(poster.pdfUrl),
                      key: ValueKey(poster.id),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showPosterComments(
  BuildContext context,
  EventEposter poster,
  AppBrand brand,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PosterCommentsSheet(poster: poster, brand: brand),
  );
}

class _PosterCommentsSheet extends StatefulWidget {
  const _PosterCommentsSheet({required this.poster, required this.brand});

  final EventEposter poster;
  final AppBrand brand;

  @override
  State<_PosterCommentsSheet> createState() => _PosterCommentsSheetState();
}

class _PosterCommentsSheetState extends State<_PosterCommentsSheet> {
  final _client = EventEposterClient();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  List<EposterComment> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreName();
    _load();
  }

  Future<void> _restoreName() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      _nameController.text =
          preferences.getString('eposter_comment_name') ?? '';
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final comments = await _client.fetchComments(
        widget.brand.code,
        widget.poster.id,
      );
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger les commentaires.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final name = _nameController.text.trim();
    final content = _commentController.text.trim();
    if (name.isEmpty || content.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final comment = await _client.postComment(
        eventCode: widget.brand.code,
        posterId: widget.poster.id,
        authorName: name,
        content: content,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('eposter_comment_name', name);
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
      setState(() => _comments = [comment, ..._comments]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Le commentaire n’a pas pu être publié.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .5,
      maxChildSize: .96,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _posterCanvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 30),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _posterLine,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: widget.brand.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.forum_rounded, color: Colors.white),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISCUSSION DU POSTER',
                        style: TextStyle(
                          color: _posterMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.poster.displayNumber,
                        style: const TextStyle(
                          color: _posterInk,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  tooltip: 'Actualiser',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              widget.poster.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _posterMuted,
                height: 1.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _posterLine),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    decoration: _commentDecoration(
                      'Votre nom',
                      Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _commentController,
                    maxLength: 1000,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _commentDecoration(
                      'Votre commentaire ou question',
                      Icons.chat_bubble_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.brand.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_sending ? 'Publication…' : 'Publier'),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Commentaires',
                    style: TextStyle(
                      color: _posterInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${_comments.length}',
                  style: const TextStyle(
                    color: _posterMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: CircularProgressIndicator(
                    color: widget.brand.primaryColor,
                  ),
                ),
              )
            else if (_comments.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _posterLine),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: _posterMuted,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Soyez le premier à commenter ce poster.',
                      style: TextStyle(color: _posterMuted, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._comments.map(
                (comment) =>
                    _PosterCommentCard(comment: comment, brand: widget.brand),
              ),
          ],
        ),
      ),
    ),
  );

  InputDecoration _commentDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: _posterCanvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      );
}

class _PosterCommentCard extends StatelessWidget {
  const _PosterCommentCard({required this.comment, required this.brand});

  final EposterComment comment;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _posterLine),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: brand.primaryColor.withValues(alpha: .1),
          child: Text(
            comment.authorName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: brand.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: _posterInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _posterCommentDate(comment.createdAt),
                    style: const TextStyle(color: _posterMuted, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.content,
                style: const TextStyle(
                  color: Color(0xFF3F4B5C),
                  height: 1.4,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _posterCommentDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

void _showPosterDetails(
  BuildContext context,
  EventEposter poster,
  AppBrand brand,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: .62,
      minChildSize: .35,
      maxChildSize: .9,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _posterLine,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: brand.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    poster.displayNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    poster.category.toUpperCase(),
                    style: TextStyle(
                      color: brand.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              poster.title,
              style: const TextStyle(
                color: _posterInk,
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            if (poster.authors?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _PosterDetailBlock(
                icon: Icons.groups_2_rounded,
                label: 'AUTEURS',
                value: poster.authors!,
                brand: brand,
              ),
            ],
            if (poster.affiliations?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _PosterDetailBlock(
                icon: Icons.account_balance_rounded,
                label: 'AFFILIATIONS',
                value: poster.affiliations!,
                brand: brand,
              ),
            ],
            if (poster.abstractText?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 20),
              const Text(
                'RÉSUMÉ',
                style: TextStyle(
                  color: _posterMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                poster.abstractText!,
                style: const TextStyle(
                  color: _posterInk,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
            if (poster.award?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D8),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFF7D873)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFB87900),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        poster.award!,
                        style: const TextStyle(
                          color: Color(0xFF765000),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _PosterDetailBlock extends StatelessWidget {
  const _PosterDetailBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.brand,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _posterCanvas,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: brand.primaryColor, size: 19),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: brand.primaryColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _posterInk,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
