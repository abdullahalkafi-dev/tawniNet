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
        'jobId': jobId,
        'revieweeId': revieweeId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      fromData: (data) => data,
    );

    if (response.success) {
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      // Success even if body shape is unexpected — review was saved.
      return <String, dynamic>{};
    }
    throw Exception(response.message ?? 'Failed to submit review');
  }

  Future<List<dynamic>> getUserReviews(String userId) async {
    final endpoint = '${ApiConstants.reviews}/user/$userId';
    final response = await _api.get(
      endpoint,
      fromData: (data) => data,
    );

    if (!response.success) return [];
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['docs'] is List) {
      return data['docs'] as List;
    }
    return [];
  }
}
