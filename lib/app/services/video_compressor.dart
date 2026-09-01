import 'dart:io';
import 'package:video_compress/video_compress.dart';

class VideoCompressor {
  /// Compress video to 720p equivalent quality.
  /// Returns compressed file, or null on failure.
  static Future<File?> compress(String inputPath) async {
    final mediaInfo = await VideoCompress.compressVideo(
      inputPath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );
    return mediaInfo?.file;
  }
}
