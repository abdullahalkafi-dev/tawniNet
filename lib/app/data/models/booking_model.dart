enum BookingStatus { inProgress, completed, cancelled }

class Booking {
  final String id;
  final String workerName;
  final String workerImage;
  final String category;
  final BookingStatus status;
  final String jobType;
  final String date;
  final String time;
  final String location;
  final double budget;
  final String description;
  final List<String> photos;

  Booking({
    required this.id,
    required this.workerName,
    required this.workerImage,
    required this.category,
    required this.status,
    required this.jobType,
    required this.date,
    required this.time,
    required this.location,
    required this.budget,
    required this.description,
    required this.photos,
  });
}
