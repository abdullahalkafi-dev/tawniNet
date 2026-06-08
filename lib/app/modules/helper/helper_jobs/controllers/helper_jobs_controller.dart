import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:get/get.dart';

class HelperJobsController extends GetxController {
  final activeJobs = <dynamic>[
    {
      'id': '1',
      'clientName': 'T-trades',
      'clientImage': 'https://i.pravatar.cc/150?u=ttrades',
      'location': '123 Elm Street, Morocco',
      'status': 'Inprogress',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum. Lorem quam vitae mus metus tortor turpis at.',
      'photos': ['https://i.pravatar.cc/150?u=p1', 'https://i.pravatar.cc/150?u=p2', 'https://i.pravatar.cc/150?u=p3'],
      'orderBy': 'T-trades',
    },
    {
      'id': '2',
      'clientName': 'Jony Barlin',
      'clientImage': 'https://i.pravatar.cc/150?u=jony',
      'location': '769 Elm Street, Morocco',
      'status': 'Inprogress',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'Jony Barlin',
    },
    {
      'id': '3',
      'clientName': 'Brown bits',
      'clientImage': 'https://i.pravatar.cc/150?u=brown',
      'location': '123 Elm Street, Morocco',
      'status': 'Inprogress',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'Brown bits',
    },
    {
      'id': '4',
      'clientName': 'Marschal',
      'clientImage': 'https://i.pravatar.cc/150?u=marschal',
      'location': '123 Elm Street, Morocco',
      'status': 'Inprogress',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'Marschal',
    },
    {
      'id': '5',
      'clientName': 'Kabul kal',
      'clientImage': 'https://i.pravatar.cc/150?u=kabul',
      'location': '123 Elm Street, Morocco',
      'status': 'Inprogress',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'Kabul kal',
    },
  ].obs;

  final completedJobs = <dynamic>[
    {
      'id': '6',
      'clientName': 'Marschal',
      'clientImage': 'https://i.pravatar.cc/150?u=marschal2',
      'location': '123 Elm Street, Morocco',
      'status': 'Completed',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'Marschal',
      'earnedAmount': 88.0,
    },
    {
      'id': '7',
      'clientName': 'Brown bits',
      'clientImage': 'https://i.pravatar.cc/150?u=brown2',
      'location': '123 Elm Street, Morocco',
      'status': 'Completed',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'Brown bits',
      'earnedAmount': 88.0,
    },
    {
      'id': '8',
      'clientName': 'T-trades',
      'clientImage': 'https://i.pravatar.cc/150?u=ttrades2',
      'location': '123 Elm Street, Morocco',
      'status': 'Completed',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'description': 'Tasks Required...',
      'photos': [],
      'orderBy': 'T-trades',
      'earnedAmount': 88.0,
    },
  ].obs;

  final cancelledJobs = <dynamic>[
    {
      'id': '9',
      'clientName': 'Marschal',
      'clientImage': 'https://i.pravatar.cc/150?u=marschal3',
      'location': '123 Elm Street, Morocco',
      'status': 'Cancelled',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'cancelledDate': 'March 12, 2026',
      'cancelledBy': 'Marschal',
      'reason': 'Emergency came up, unable to fulfill the appointment',
      'description': 'Lorem ipsum dolor sit amet consectetur...',
      'orderBy': 'Marschal',
    },
    {
      'id': '10',
      'clientName': 'Brown bits',
      'clientImage': 'https://i.pravatar.cc/150?u=brown3',
      'location': '123 Elm Street, Morocco',
      'status': 'Cancelled',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'cancelledDate': 'March 12, 2026',
      'cancelledBy': 'Brown bits',
      'reason': 'Schedule conflict',
      'description': 'Tasks Required...',
      'orderBy': 'Brown bits',
    },
    {
      'id': '11',
      'clientName': 'T-trades',
      'clientImage': 'https://i.pravatar.cc/150?u=ttrades3',
      'location': '123 Elm Street, Morocco',
      'status': 'Cancelled',
      'jobType': 'Plumber',
      'bookingDate': 'Mar 12, 2026',
      'preferredTime': '10:00AM - 12:00 PM',
      'budget': 100.0,
      'distance': '2km away',
      'cancelledDate': 'March 12, 2026',
      'cancelledBy': 'T-trades',
      'reason': 'No longer needed',
      'description': 'Tasks Required...',
      'orderBy': 'T-trades',
    },
  ].obs;

  void onJobTap(dynamic job, String type) {
    if (type == 'active') {
      Get.toNamed(Routes.activeJobDetails, arguments: job);
    } else if (type == 'completed') {
      Get.toNamed(Routes.completedJobDetails, arguments: job);
    } else {
      Get.toNamed(Routes.helperCancelDetails, arguments: job);
    }
  }

  void cancelJob(String id) {
    Get.back();
    Get.back();
    Get.snackbar('Cancelled', 'Job has been cancelled',
        snackPosition: SnackPosition.BOTTOM);
  }
}
