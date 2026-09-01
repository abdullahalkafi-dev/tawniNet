import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:get/get.dart';

class ReviewService extends GetxService {
  late final ApiClient _api;

  ReviewService() {
    _api = Get.find<ApiClient>();
  }

  Future<Map<String, dynamic>> submitReview({
    required String jobId,
    required String revieweeId,
    required double rating,
    String? comment,
  }) async {
    final response = await _api.post(
      ApiConstants.reviews,
      data: {
        'job': jobId,
        'reviewee': revieweeId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to submit review');
  }

  Future<List<dynamic>> getUserReviews(String userId) async {
    final endpoint = '${ApiConstants.reviews}/user/$userId';
    final response = await _api.get(
      endpoint,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as List<dynamic>;
    }
    return [];
  }
}
