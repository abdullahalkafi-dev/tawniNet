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

  Future<List<dynamic>> getNearbyJobs({String? category, double? maxDistance}) async {
    final Map<String, dynamic> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (maxDistance != null) queryParams['maxDistance'] = maxDistance;

    final response = await _api.get(
      ApiConstants.jobsNearby,
      queryParameters: queryParams,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as List<dynamic>;
    }
    return [];
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

  Future<Map<String, dynamic>> updateJobStatus(String jobId, String status) async {
    final endpoint = '${ApiConstants.jobs}/$jobId';
    final response = await _api.patch(
      endpoint,
      data: {'status': status},
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to update job status');
  }
}
