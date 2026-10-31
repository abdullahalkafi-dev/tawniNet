import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/media_downloader.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final resolved =
                  ApiConstants.resolveImageUrl(widget.imageUrls[index]) ??
                      widget.imageUrls[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: AppNetworkImage(url: resolved, fit: BoxFit.contain),
                ),
              );
            },
          ),

          // Back button
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 8,
            start: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // Download button
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 8,
            end: 8,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  final url = ApiConstants.resolveImageUrl(
                          widget.imageUrls[_currentIndex]) ??
                      widget.imageUrls[_currentIndex];
                  final ext = url.split('.').last.split('?').first;
                  MediaDownloader.download(
                    url: url,
                    fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.$ext',
                  );
                },
              ),
            ),
          ),

          // Page indicator (only show if multiple images)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white38,
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
