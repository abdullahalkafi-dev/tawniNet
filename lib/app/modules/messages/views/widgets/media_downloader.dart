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
        'ui_downloading'.tr,
        'ui_saving_file'.trParams({'file': fileName}),
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
        AppFeedback.error('ui_could_not_access_storage'.tr);
        return;
      }

      final filePath = '${dir.path}/$fileName';
      await dio.download(url, filePath);

      AppFeedback.success(
        'ui_saved_to'.trParams({'path': '${Platform.isAndroid ? "Downloads" : "Files"}/$fileName'}),
        title: 'ui_downloaded'.tr,
      );
    } catch (e) {
      AppFeedback.error('ui_failed_to_download'.trParams({'error': '$e'}));
    }
  }
}
