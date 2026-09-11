import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/media_downloader.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Shared support media grid for helper + client contact screens.
/// Images: tap → full-screen preview + download.
/// Videos: tap → full-screen player + download.
class SupportMediaGrid extends StatelessWidget {
  const SupportMediaGrid({
    super.key,
    required this.urls,
    this.tileSize,
  });

  final List<String> urls;
  final double? tileSize;

  static bool isVideoUrl(String url) {
    final u = url.toLowerCase();
    return RegExp(r'\.(mp4|mov|avi|webm|mkv|3gp|m4v)(\?.*)?$').hasMatch(u) ||
        u.contains('/videos/') ||
        u.contains('/upload/video');
  }

  void _open(BuildContext context, String url) {
    if (isVideoUrl(url)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => SupportVideoPreviewPage(url: url),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => SupportImagePreviewPage(url: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final size = tileSize ?? MediaQuery.of(context).size.width * 0.38;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: urls.map((url) {
        final video = isVideoUrl(url);
        return GestureDetector(
          onTap: () => _open(context, url),
          child: Container(
            width: size,
            height: video ? size * 0.75 : size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.35),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: video
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.black87,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white.withOpacity(0.92),
                            size: 42,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          Icons.videocam_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Image',
                            style: AppStyles.bodyMedium.copyWith(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class SupportImagePreviewPage extends StatelessWidget {
  const SupportImagePreviewPage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Image', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => MediaDownloader.download(
              url: url,
              fileName: url.split('/').last.split('?').first,
            ),
          ),
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load image.\nUse download or open in browser.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupportVideoPreviewPage extends StatefulWidget {
  const SupportVideoPreviewPage({super.key, required this.url});

  final String url;

  @override
  State<SupportVideoPreviewPage> createState() =>
      _SupportVideoPreviewPageState();
}

class _SupportVideoPreviewPageState extends State<SupportVideoPreviewPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Video', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => MediaDownloader.download(
              url: widget.url,
              fileName: widget.url.split('/').last.split('?').first,
            ),
          ),
          IconButton(
            tooltip: 'Open externally',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => launchUrl(
              Uri.parse(widget.url),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not play video here.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(widget.url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Open in another app'),
                    ),
                  ],
                ),
              )
            : !_ready
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio == 0
                          ? 16 / 9
                          : _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          if (!_controller.value.isPlaying)
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: AppColors.primary,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white12,
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
}
