import 'dart:io';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class MediaDownloader {
  static Future<void> download({
    required String url,
    required String fileName,
  }) async {
    try {
      Get.snackbar(
        'Downloading...',
        'Saving $fileName',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final dio = Dio();

      // Get downloads directory
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        AppFeedback.error('Could not access storage');
        return;
      }

      final filePath = '${dir.path}/$fileName';
      await dio.download(url, filePath);

      AppFeedback.success(
        'Saved to ${Platform.isAndroid ? "Downloads" : "Files"}/$fileName',
        title: 'Downloaded',
      );
    } catch (e) {
      AppFeedback.error('Failed to download: $e');
    }
  }
}
