import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/app_brand.dart';

const _boardInk = Color(0xFF10231F);
const _boardMuted = Color(0xFF667A74);
const _boardCanvas = Color(0xFFF4F7F5);
const _boardLine = Color(0xFFE1E9E5);

class BoardScreen extends StatelessWidget {
  const BoardScreen({required this.brand, super.key});

  final AppBrand brand;

  @override
  Widget build(BuildContext context) {
    final members = brand.boardMembers;
    return Scaffold(
      backgroundColor: Color.lerp(brand.primaryColor, Colors.black, .32),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ColoredBox(
            color: _boardCanvas,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _BoardHeader(brand: brand)),
                  if (members.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _BoardEmptyState(),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                      sliver: SliverToBoxAdapter(
                        child:
                            _FeaturedMember(member: members.first, brand: brand)
                                .animate()
                                .fadeIn(duration: 450.ms)
                                .slideY(begin: .035, end: 0),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 27, 20, 13),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle(
                          count: members.length - 1,
                          brand: brand,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                      sliver: SliverList.builder(
                        itemCount: members.length - 1,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              _BoardMemberCard(
                                    member: members[index + 1],
                                    brand: brand,
                                    index: index + 2,
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (index * 65).ms,
                                    duration: 380.ms,
                                  )
                                  .slideX(begin: .035, end: 0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.brand});

  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    height: 205,
    padding: const EdgeInsets.fromLTRB(14, 12, 20, 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(brand.primaryColor, Colors.black, .4)!,
          brand.primaryColor,
          Color.lerp(brand.primaryColor, brand.secondaryColor, .16)!,
        ],
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      boxShadow: [
        BoxShadow(
          color: brand.primaryColor.withValues(alpha: .2),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -35,
          top: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .08),
                width: 28,
              ),
            ),
          ),
        ),
        Positioned(
          right: 36,
          bottom: -45,
          child: Icon(
            Icons.account_balance_rounded,
            size: 150,
            color: Colors.white.withValues(alpha: .055),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: .13),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 62,
                  height: 46,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Color(0x20000000), blurRadius: 15),
                    ],
                  ),
                  child: Image.asset(brand.logoAsset, fit: BoxFit.contain),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'ASSOCIATION',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bureau exécutif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Une équipe engagée au service de la profession',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FeaturedMember extends StatelessWidget {
  const _FeaturedMember({required this.member, required this.brand});

  final EventBoardMember member;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _showMemberSheet(context, member, brand),
      child: SizedBox(
        height: 335,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BoardPortrait(member: member, brand: brand),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [.32, 1],
                  colors: [Colors.transparent, Color(0xE60B211C)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .93),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: brand.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      member.role.toUpperCase(),
                      style: TextStyle(
                        color: brand.primaryColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DIRECTION & VISION',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.08,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 19,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.count, required this.brand});

  final int count;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GOUVERNANCE',
              style: TextStyle(
                color: brand.primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.45,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Les membres du bureau',
              style: TextStyle(
                color: _boardInk,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.55,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: brand.secondaryColor.withValues(alpha: .52),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count membres',
          style: TextStyle(
            color: brand.primaryColor,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _BoardMemberCard extends StatelessWidget {
  const _BoardMemberCard({
    required this.member,
    required this.brand,
    required this.index,
  });

  final EventBoardMember member;
  final AppBrand brand;
  final int index;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _showMemberSheet(context, member, brand),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          border: Border.all(color: _boardLine),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 116,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _BoardPortrait(member: member, brand: brand),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$index'.padLeft(2, '0'),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: brand.secondaryColor.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.role.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: brand.primaryColor,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      member.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _boardInk,
                        height: 1.16,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 13),
              decoration: BoxDecoration(
                color: _boardCanvas,
                shape: BoxShape.circle,
                border: Border.all(color: _boardLine),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: _boardMuted,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BoardPortrait extends StatelessWidget {
  const _BoardPortrait({
    required this.member,
    required this.brand,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  final EventBoardMember member;
  final AppBrand brand;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final fallback = _BoardPortraitFallback(member: member, brand: brand);
    return member.photoUrl == null
        ? fallback
        : Image.network(
            member.photoUrl!,
            fit: fit,
            alignment: alignment,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback,
            errorBuilder: (_, _, _) => fallback,
          );
  }
}

class _BoardPortraitFallback extends StatelessWidget {
  const _BoardPortraitFallback({required this.member, required this.brand});

  final EventBoardMember member;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brand.secondaryColor.withValues(alpha: .72),
          Color.lerp(brand.secondaryColor, brand.primaryColor, .23)!,
        ],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: -18,
          bottom: -20,
          child: Icon(
            Icons.person_rounded,
            size: 130,
            color: Colors.white.withValues(alpha: .18),
          ),
        ),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .88),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Text(
            _initials(member.name),
            style: TextStyle(
              color: brand.primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BoardEmptyState extends StatelessWidget {
  const _BoardEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Les membres du bureau seront publiés prochainement.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _boardMuted, height: 1.5),
      ),
    ),
  );
}

void _showMemberSheet(
  BuildContext context,
  EventBoardMember member,
  AppBrand brand,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          decoration: const BoxDecoration(
            color: _boardCanvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _boardLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: brand.secondaryColor.withValues(alpha: .28),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x17000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _BoardPortrait(
                        member: member,
                        brand: brand,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: brand.secondaryColor.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.role.toUpperCase(),
                    style: TextStyle(
                      color: brand.primaryColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  member.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _boardInk,
                    fontSize: 23,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                if (member.bio?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 15),
                  Text(
                    member.bio!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _boardMuted,
                      height: 1.55,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && !word.toLowerCase().startsWith('dr'))
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
