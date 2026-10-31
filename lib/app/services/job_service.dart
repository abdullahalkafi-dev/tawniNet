import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:get/get.dart';

class JobService extends GetxService {
  late final ApiClient _api;

  JobService() {
    _api = Get.find<ApiClient>();
  }

  Map<String, dynamic> _asMap(dynamic data, String failure) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException(failure);
  }

  Future<Map<String, dynamic>> _post(String endpoint, {dynamic data, required String failure}) async {
    final response = await _api.post(endpoint, data: data, fromData: (d) => d);
    if (response.success) {
      return response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
    }
    throw ApiException(response.message ?? failure);
  }

  Future<Map<String, dynamic>> acceptJob(String jobId) =>
      _post(ApiConstants.acceptJob(jobId), failure: 'err_http_unknown'.tr);

  /// Helper: "I'm on my way" — tracking starts for the client.
  Future<Map<String, dynamic>> markOnTheWay(String jobId) =>
      _post(ApiConstants.jobOnTheWay(jobId), failure: 'err_http_unknown'.tr);

  /// Helper: "I've arrived".
  Future<Map<String, dynamic>> markArrived(String jobId) =>
      _post(ApiConstants.jobArrived(jobId), failure: 'err_http_unknown'.tr);

  /// Helper: "the work is done" — the client then confirms (or it completes by itself).
  Future<Map<String, dynamic>> markFinished(String jobId) =>
      _post(ApiConstants.jobFinish(jobId), failure: 'err_http_unknown'.tr);

  /// Client or helper: something went wrong; automatic completion is paused and support decides.
  Future<Map<String, dynamic>> reportProblem(String jobId, String message) =>
      _post(ApiConstants.jobReportProblem(jobId), data: {'message': message}, failure: 'err_http_unknown'.tr);

  Future<Map<String, dynamic>> getNearbyJobs({
    String? category,
    double? maxDistance,
    double? lat,
    double? lon,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (category != null) queryParams['category'] = category;
    // The API expects metres
    if (maxDistance != null) queryParams['maxDistance'] = maxDistance;
    if (lat != null && lon != null) {
      queryParams['lat'] = lat;
      queryParams['lon'] = lon;
    }

    final response = await _api.get(
      ApiConstants.jobsNearby,
      queryParameters: queryParams,
      fromData: (data) => data,
    );

    final data = response.data;
    if (response.success && data != null) {
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is List) return {'docs': data, 'total': data.length};
    }
    return {'docs': <dynamic>[], 'total': 0};
  }

  Future<Map<String, dynamic>> getJobById(String jobId) async {
    final response = await _api.get(ApiConstants.jobById(jobId), fromData: (data) => data);
    return _asMap(response.data, response.message ?? 'booking_not_found'.tr);
  }

  /// Everything at once (active / awaiting / unpaid + the latest finished ones).
  Future<Map<String, dynamic>> getMyBookings() async {
    final response = await _api.get(ApiConstants.jobsMyBookings, fromData: (data) => data);
    final data = response.data;
    if (response.success && data is Map) {
      return {
        'active': (data['active'] as List?) ?? [],
        // Paid, still looking for a helper — must not be dropped.
        'awaiting': (data['awaiting'] as List?) ?? [],
        'completed': (data['completed'] as List?) ?? [],
        'cancelled': (data['cancelled'] as List?) ?? [],
        'unpaid': (data['unpaid'] as List?) ?? [],
        'counts': data['counts'] is Map ? Map<String, dynamic>.from(data['counts'] as Map) : <String, dynamic>{},
      };
    }
    throw ApiException(response.message ?? 'ui_could_not_load_bookings_pull_down_to'.tr);
  }

  /// One more page of the finished tabs (`completed` / `cancelled`).
  Future<Map<String, dynamic>> getMyBookingsPage(String tab, int page) async {
    final response = await _api.get(
      ApiConstants.jobsMyBookings,
      queryParameters: {'tab': tab, 'page': page, 'limit': 30},
      fromData: (data) => data,
    );
    return _asMap(response.data, response.message ?? 'err_http_unknown'.tr);
  }

  Future<Map<String, dynamic>> getMyAssignedJobs() async {
    final response = await _api.get(ApiConstants.jobsMyAssigned, fromData: (data) => data);
    final data = response.data;
    if (response.success && data is Map) {
      return {
        'active': (data['active'] as List?) ?? [],
        'completed': (data['completed'] as List?) ?? [],
        'cancelled': (data['cancelled'] as List?) ?? [],
        'counts': data['counts'] is Map ? Map<String, dynamic>.from(data['counts'] as Map) : <String, dynamic>{},
      };
    }
    throw ApiException(response.message ?? 'ui_could_not_load_jobs_pull_down_to'.tr);
  }

  Future<Map<String, dynamic>> getMyAssignedJobsPage(String tab, int page) async {
    final response = await _api.get(
      ApiConstants.jobsMyAssigned,
      queryParameters: {'tab': tab, 'page': page, 'limit': 30},
      fromData: (data) => data,
    );
    return _asMap(response.data, response.message ?? 'err_http_unknown'.tr);
  }

  Future<Map<String, dynamic>> retryJobCheckout(String jobId) async {
    final response = await _api.post(ApiConstants.jobCheckout(jobId), fromData: (data) => data);
    return _asMap(response.data, response.message ?? 'ui_could_not_start_payment_try_again'.tr);
  }

  Future<Map<String, dynamic>> completeJob(String jobId, {String? note}) =>
      _post(ApiConstants.completeJob(jobId),
          data: note != null ? {'note': note} : <String, dynamic>{}, failure: 'err_http_unknown'.tr);

  Future<Map<String, dynamic>> cashReceived(String jobId) =>
      _post(ApiConstants.cashReceived(jobId), failure: 'err_http_unknown'.tr);

  Future<Map<String, dynamic>> cancelJob(String jobId, String reason, {String? code}) =>
      _post(ApiConstants.cancelJob(jobId),
          data: {'reason': reason, if (code != null) 'code': code}, failure: 'err_http_unknown'.tr);
}
