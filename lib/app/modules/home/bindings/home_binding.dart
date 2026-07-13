import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<BookingController>(
      () => BookingController(),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
    // MessagesController is registered permanently in main.dart
  }
}
