import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/app_brand.dart';
import '../data/event_media_client.dart';

const _playerInk = Color(0xFF10231F);
const _playerMuted = Color(0xFF667A74);
const _playerCanvas = Color(0xFFF3F6F4);
const _playerLine = Color(0xFFE0E8E4);

class MediaVideoPlayerScreen extends StatefulWidget {
  const MediaVideoPlayerScreen({
    required this.item,
    required this.categoryLabel,
    required this.brand,
    super.key,
  });

  final EventMediaItem item;
  final String categoryLabel;
  final AppBrand brand;

  @override
  State<MediaVideoPlayerScreen> createState() => _MediaVideoPlayerScreenState();
}

class _MediaVideoPlayerScreenState extends State<MediaVideoPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.item.youtubeVideoId!,
      autoPlay: true,
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

  @override
  void dispose() {
    _controller.close();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    return Scaffold(
      backgroundColor: _playerCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                _PlayerTopBar(brand: brand),
                ColoredBox(
                  color: Colors.black,
                  child: YoutubePlayer(
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    enableFullScreenOnVerticalDrag: true,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: brand.secondaryColor.withValues(
                                  alpha: .5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: brand.primaryColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'VIDÉO',
                                    style: TextStyle(
                                      color: brand.primaryColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.item.publishedOn != null) ...[
                              const Spacer(),
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: _playerMuted,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _date(widget.item.publishedOn!),
                                style: const TextStyle(
                                  color: _playerMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.categoryLabel.toUpperCase(),
                          style: TextStyle(
                            color: brand.primaryColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            color: _playerInk,
                            height: 1.12,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.7,
                          ),
                        ),
                        if (widget.item.description?.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(color: _playerLine),
                            ),
                            child: Text(
                              widget.item.description!,
                              style: const TextStyle(
                                color: Color(0xFF334842),
                                height: 1.55,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: brand.primaryColor.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.screen_rotation_alt_rounded,
                                color: brand.primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Text(
                                  'Touchez l’icône plein écran dans la vidéo pour une lecture immersive.',
                                  style: TextStyle(
                                    color: _playerMuted,
                                    height: 1.35,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({required this.brand});

  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    color: _playerInk,
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 3),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MÉDIATHÈQUE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Lecture en cours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(
            Icons.high_quality_rounded,
            color: Colors.white54,
            size: 22,
          ),
        ),
      ],
    ),
  );
}
