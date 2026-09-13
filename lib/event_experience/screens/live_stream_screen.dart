import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/app_brand.dart';
import '../data/live_comment_client.dart';

const _liveInk = Color(0xFF10231F);
const _liveCanvas = Color(0xFFF3F6F4);
const _liveMuted = Color(0xFF667A74);
const _liveLine = Color(0xFFE0E8E4);

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({required this.brand, super.key});

  final AppBrand brand;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final _commentClient = LiveCommentClient();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  YoutubePlayerController? _playerController;
  Timer? _refreshTimer;
  List<LiveComment> _comments = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  LiveStreamConfig get live => widget.brand.liveStream!;

  @override
  void initState() {
    super.initState();
    final videoId = live.youtubeVideoId;
    if (videoId != null) {
      _playerController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: live.isLive,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          captionLanguage: 'fr',
          interfaceLanguage: 'fr',
          strictRelatedVideos: true,
          privacyEnhancedMode: true,
        ),
      );
    }
    _restoreName();
    _loadComments();
    if (live.commentsEnabled && live.commentsUrl != null) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _loadComments(silent: true),
      );
    }
  }

  Future<void> _restoreName() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      _nameController.text = preferences.getString('live_comment_name') ?? '';
    }
  }

  Future<void> _loadComments({bool silent = false}) async {
    final url = live.commentsUrl;
    if (!live.commentsEnabled || url == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final comments = await _commentClient.fetch(url);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les commentaires.';
      });
    }
  }

  Future<void> _sendComment() async {
    final url = live.commentsUrl;
    final name = _nameController.text.trim();
    final content = _commentController.text.trim();
    if (url == null || name.isEmpty || content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await _commentClient.post(
        url: url,
        authorName: name,
        content: content,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('live_comment_name', name);
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _comments = [comment, ..._comments];
        _sending = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Le commentaire n’a pas pu être envoyé. Réessayez.';
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _playerController?.close();
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    return Scaffold(
      backgroundColor: _liveCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: RefreshIndicator(
              color: brand.primaryColor,
              onRefresh: _loadComments,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.zero,
                children: [
                  _LiveTopBar(brand: brand, isLive: live.isLive),
                  _buildPlayer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (live.isLive)
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE92D3B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _LiveDot(),
                                    SizedBox(width: 6),
                                    Text(
                                      'EN DIRECT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                live.title,
                                style: const TextStyle(
                                  color: _liveInk,
                                  fontSize: 23,
                                  height: 1.15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (live.description?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 11),
                          Text(
                            live.description!,
                            style: const TextStyle(
                              color: _liveMuted,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Icon(
                              Icons.forum_rounded,
                              color: brand.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: Text(
                                'Commentaires du direct',
                                style: TextStyle(
                                  color: _liveInk,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${_comments.length}',
                              style: const TextStyle(
                                color: _liveMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (!live.commentsEnabled)
                          const _LiveInfoCard(
                            icon: Icons.comments_disabled_rounded,
                            text:
                                'Les commentaires sont désactivés pour ce direct.',
                          )
                        else ...[
                          _CommentComposer(
                            brand: brand,
                            nameController: _nameController,
                            commentController: _commentController,
                            sending: _sending,
                            onSend: _sendComment,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFB42318),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (_loading)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  color: brand.primaryColor,
                                ),
                              ),
                            )
                          else if (_comments.isEmpty)
                            const _LiveInfoCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              text: 'Soyez le premier à commenter ce direct.',
                            )
                          else
                            ..._comments.map(
                              (comment) =>
                                  _CommentCard(comment: comment, brand: brand),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final controller = _playerController;
    if (controller != null) {
      return ColoredBox(
        color: Colors.black,
        child: YoutubePlayer(
          controller: controller,
          aspectRatio: 16 / 9,
          enableFullScreenOnVerticalDrag: true,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: FilledButton.icon(
            onPressed: live.sourceUrl == null
                ? null
                : () => launchUrl(
                    Uri.parse(live.sourceUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Ouvrir le direct'),
          ),
        ),
      ),
    );
  }
}

class _LiveTopBar extends StatelessWidget {
  const _LiveTopBar({required this.brand, required this.isLive});

  final AppBrand brand;
  final bool isLive;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    color: _liveInk,
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Container(
          width: 45,
          height: 37,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Image.asset(brand.logoAsset, fit: BoxFit.contain),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brand.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isLive ? 'Diffusion en direct' : 'Diffusion vidéo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (isLive)
          const Padding(padding: EdgeInsets.only(right: 12), child: _LiveDot()),
      ],
    ),
  );
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .38, end: 1).animate(_controller),
    child: const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    ),
  );
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.brand,
    required this.nameController,
    required this.commentController,
    required this.sending,
    required this.onSend,
  });

  final AppBrand brand;
  final TextEditingController nameController;
  final TextEditingController commentController;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _liveLine),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        TextField(
          controller: nameController,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration(
            label: 'Votre nom',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: commentController,
          maxLength: 1000,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(
            label: 'Votre commentaire',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: brand.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(sending ? 'Envoi…' : 'Publier le commentaire'),
          ),
        ),
      ],
    ),
  );

  InputDecoration _decoration({
    required String label,
    required IconData icon,
  }) => InputDecoration(
    labelText: label,
    counterText: '',
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: _liveCanvas,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.brand});

  final LiveComment comment;
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _liveLine),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: brand.secondaryColor,
          child: Text(
            comment.authorName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: brand.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
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
                        color: _liveInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _date(comment.createdAt),
                    style: const TextStyle(color: _liveMuted, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.content,
                style: const TextStyle(
                  color: Color(0xFF334842),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _date(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }
}

class _LiveInfoCard extends StatelessWidget {
  const _LiveInfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _liveLine),
    ),
    child: Column(
      children: [
        Icon(icon, color: _liveMuted, size: 30),
        const SizedBox(height: 9),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _liveMuted, fontSize: 12),
        ),
      ],
    ),
  );
}
