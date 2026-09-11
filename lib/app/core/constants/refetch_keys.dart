class RefetchKeys {
  RefetchKeys._();

  static const String userProfile = 'userProfile';
  static const String categories = 'categories';
  static const String activeBookings = 'activeBookings';
  static const String completedBookings = 'completedBookings';
  static const String cancelledBookings = 'cancelledBookings';
  static const String unpaidBookings = 'unpaidBookings';
  static const String helperJobs = 'helperJobs';
  static const String helperProfile = 'helperProfile';
  static const String nearbyJobs = 'nearbyJobs';
  static const String popularServices = 'popularServices';
  static const String popularHelpers = 'popularHelpers';

  /// Refresh every list that depends on job status / money / reviews.
  static const List<String> jobPipeline = [
    activeBookings,
    unpaidBookings,
    completedBookings,
    cancelledBookings,
    helperJobs,
    nearbyJobs,
    popularServices,
    popularHelpers,
  ];
}
