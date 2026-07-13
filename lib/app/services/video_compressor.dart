import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoCompressor {
  /// Compress video to 720p, 2Mbps bitrate.
  /// Returns compressed file path, or null on failure.
  static Future<File?> compress(String inputPath) async {
    final outputDir = await getTemporaryDirectory();
    final outputPath =
        '${outputDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final session = await FFmpegKit.execute(
      '-i "$inputPath" '
      '-vf "scale=-2:720" '
      '-c:v libx264 -preset fast -b:v 2M '
      '-c:a aac -b:a 128k '
      '-movflags +faststart '
      '"$outputPath"',
    );

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    }
    return null;
  }
}
