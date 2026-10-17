import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../design/colors.dart';
import '../../design/radii.dart';
import '../../design/sprout_assets.dart';
import '../../design/typography.dart';

class SproutScanVideoCard extends StatefulWidget {
  final VoidCallback onScanTap;
  final VoidCallback onGalleryTap;

  const SproutScanVideoCard({
    super.key,
    required this.onScanTap,
    required this.onGalleryTap,
  });

  @override
  State<SproutScanVideoCard> createState() => _SproutScanVideoCardState();
}

class _SproutScanVideoCardState extends State<SproutScanVideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/sprout_scan.mp4');
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0); // Quiet, smooth animated hero
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('VideoPlayer initialization error (fallback to illustration): $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: SproutColors.surface,
        borderRadius: SproutRadii.card,
        border: Border.all(
          color: SproutColors.sage.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: SproutColors.sproutGreen.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mascot Video Area (Entire animation visible, zero cropping)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Material(
              color: SproutColors.surface,
              child: InkWell(
                onTap: widget.onScanTap,
                child: SizedBox(
                  height: 265,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isInitialized && !_hasError)
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.contain, // Ensures Sprout's leaf ears & brackets are never cut
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: _controller.value.size.width > 0
                                  ? _controller.value.size.width
                                  : 720,
                              height: _controller.value.size.height > 0
                                  ? _controller.value.size.height
                                  : 1280,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        )
                      else
                        _buildFallbackHero(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Row: Upload from Gallery
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 14.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: SproutColors.primaryInk,
                  side: BorderSide(
                    color: SproutColors.sage.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: widget.onGalleryTap,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(
                  'Upload from Gallery',
                  style: SproutTypography.bodyBold(color: SproutColors.primaryInk),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHero() {
    return Container(
      color: SproutColors.surface,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              SproutAssets.mascotScan,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to scan ingredients',
              style: SproutTypography.bodyBold(color: SproutColors.primaryInk),
            ),
          ],
        ),
      ),
    );
  }
}
