import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:get/get.dart';

class JobService extends GetxService {
  late final ApiClient _api;

  JobService() {
    _api = Get.find<ApiClient>();
  }

  Future<Map<String, dynamic>> acceptJob(String jobId) async {
    final endpoint = '${ApiConstants.jobs}/$jobId/accept';
    final response = await _api.post(
      endpoint,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to accept job');
  }

  Future<Map<String, dynamic>> getNearbyJobs({String? category, double? maxDistance}) async {
    final Map<String, dynamic> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (maxDistance != null) queryParams['maxDistance'] = maxDistance;

    final response = await _api.get(
      ApiConstants.jobsNearby,
      queryParameters: queryParams,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is List) {
        return {'docs': data, 'total': data.length};
      }
    }
    return {'docs': <dynamic>[], 'total': 0};
  }

  Future<Map<String, dynamic>> getJobById(String jobId) async {
    final endpoint = '${ApiConstants.jobs}/$jobId';
    final response = await _api.get(
      endpoint,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to fetch job');
  }

  Future<Map<String, List<dynamic>>> getMyBookings() async {
    final response = await _api.get(
      ApiConstants.jobsMyBookings,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      return {
        'active': (data['active'] as List?) ?? [],
        // Paid, still looking for a helper — must not be dropped.
        'awaiting': (data['awaiting'] as List?) ?? [],
        'completed': (data['completed'] as List?) ?? [],
        'cancelled': (data['cancelled'] as List?) ?? [],
        'unpaid': (data['unpaid'] as List?) ?? [],
      };
    }
    return {
      'active': [],
      'awaiting': [],
      'completed': [],
      'cancelled': [],
      'unpaid': [],
    };
  }

  Future<Map<String, List<dynamic>>> getMyAssignedJobs() async {
    final response = await _api.get(
      ApiConstants.jobsMyAssigned,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      return {
        'active': (data['active'] as List?) ?? [],
        'completed': (data['completed'] as List?) ?? [],
        'cancelled': (data['cancelled'] as List?) ?? [],
      };
    }
    return {'active': [], 'completed': [], 'cancelled': []};
  }

  Future<Map<String, dynamic>> retryJobCheckout(String jobId) async {
    final response = await _api.post(
      ApiConstants.jobCheckout(jobId),
      fromData: (data) => data,
    );
    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to start payment');
  }

  Future<Map<String, dynamic>> completeJob(String jobId, {String? note}) async {
    final endpoint = ApiConstants.completeJob(jobId);
    final response = await _api.post(
      endpoint,
      data: note != null ? {'note': note} : {},
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to complete job');
  }

  Future<Map<String, dynamic>> cashReceived(String jobId) async {
    final response = await _api.post(
      ApiConstants.cashReceived(jobId),
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to confirm cash payment');
  }

  Future<Map<String, dynamic>> cancelJob(String jobId, String reason) async {
    final endpoint = ApiConstants.cancelJob(jobId);
    final response = await _api.post(
      endpoint,
      data: {'reason': reason},
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to cancel job');
  }
}
