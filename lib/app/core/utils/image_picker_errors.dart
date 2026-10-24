import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Turns an image_picker failure into a message the user can act on, and logs
/// the real cause (previously every failure was "Failed to pick images").
String imagePickerErrorMessage(Object error) {
  debugPrint('[ImagePicker] $error');
  if (error is PlatformException) {
    switch (error.code) {
      case 'photo_access_denied':
      case 'camera_access_denied':
      case 'photo_access_restricted':
        return 'picker_permission_denied'.tr;
      case 'already_active':
        return 'picker_already_open'.tr;
      case 'invalid_image':
        return 'picker_invalid_image'.tr;
    }
  }
  return 'picker_failed'.tr;
}
