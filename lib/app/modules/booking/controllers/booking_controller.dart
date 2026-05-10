import 'package:get/get.dart';
import '../../../data/models/booking_model.dart';

class BookingController extends GetxController {
  final activeBookings = <Booking>[
    Booking(
      id: '1',
      workerName: 'Ethan Carter',
      workerImage: 'https://i.pravatar.cc/150?u=ethan1',
      category: 'Cleaner',
      status: BookingStatus.inProgress,
      jobType: 'Plumber',
      date: 'Mar 12, 2026',
      time: '10:00AM - 12:00 PM',
      location: '276 New Avu.. Park, New York',
      budget: 100,
      description: 'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum...',
      photos: [
        'https://i.pravatar.cc/150?u=ethan1',
        'https://i.pravatar.cc/150?u=ethan1',
        'https://i.pravatar.cc/150?u=ethan1',
      ],
    ),
    Booking(
      id: '2',
      workerName: 'Ethan Carter',
      workerImage: 'https://i.pravatar.cc/150?u=ethan2',
      category: 'Plumber',
      status: BookingStatus.inProgress,
      jobType: 'Plumber',
      date: 'Mar 12, 2026',
      time: '10:00AM - 12:00 PM',
      location: '276 New Avu.. Park, New York',
      budget: 100,
      description: 'Tasks Required...',
      photos: [],
    ),
  ].obs;

  final completedBookings = <Booking>[
    Booking(
      id: '3',
      workerName: 'Ethan Carter',
      workerImage: 'https://i.pravatar.cc/150?u=ethan3',
      category: 'Painter',
      status: BookingStatus.completed,
      jobType: 'Painting',
      date: 'Mar 10, 2026',
      time: '10:00AM - 12:00 PM',
      location: 'Downtown Area',
      budget: 150,
      description: 'Deep painting...',
      photos: [],
    ),
  ].obs;

  final cancelledBookings = <Booking>[
    Booking(
      id: '4',
      workerName: 'Sampura',
      workerImage: 'https://i.pravatar.cc/150?u=sampura',
      category: 'Cleaner',
      status: BookingStatus.cancelled,
      jobType: 'Cleaning',
      date: 'March 12, 2026',
      time: '10:00AM - 12:00 PM',
      location: '123 Elm Street, Morocco',
      budget: 85,
      description: 'Lorem ipsum dolor sit amet consectetur...',
      photos: [],
    ),
  ].obs;

  void cancelBooking(String id) {
    // Logic to move from active to cancelled
    print('Booking $id cancelled');
  }
}
