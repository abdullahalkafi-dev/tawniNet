import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';

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

  /// Raw review from the server → the shape the review cards use.
  static Map<String, dynamic> toCardMap(Map<String, dynamic> map) {
    final reviewer = map['reviewer'];
    String name = 'ui_client'.tr;
    String avatar = '';
    if (reviewer is Map) {
      name = (reviewer['name'] ?? name).toString();
      avatar = (reviewer['avatar'] ?? '').toString();
    }
    final ratingRaw = map['rating'];
    final rating = (ratingRaw is num ? ratingRaw : (num.tryParse(ratingRaw?.toString() ?? '') ?? 0))
        .toDouble()
        .clamp(0, 5);
    final reply = map['reply'];
    return {
      'id': (map['_id'] ?? map['id'] ?? '').toString(),
      'rating': rating,
      'comment': (map['comment'] ?? '').toString(),
      'createdAt': (map['createdAt'] ?? '').toString(),
      'reviewerName': name,
      'reviewerAvatar': avatar,
      'reply': reply is Map ? (reply['text'] ?? '').toString() : '',
      'edited': map['editedAt'] != null,
      'date': AppDateTime.formatDateDisplay((map['createdAt'] ?? '').toString()),
    };
  }

  /// The reviewed person answers a review (once, public).
  Future<void> replyToReview(String reviewId, String text) async {
    final response = await _api.post('${ApiConstants.reviews}/$reviewId/reply', data: {'text': text});
    if (!response.success) throw Exception(response.message ?? 'Failed to send reply');
  }

  /// The reviewed person reports an unfair review to moderation.
  Future<void> reportReview(String reviewId, String reason) async {
    final response = await _api.post('${ApiConstants.reviews}/$reviewId/report', data: {'reason': reason});
    if (!response.success) throw Exception(response.message ?? 'Failed to report review');
  }

  /// The author corrects their own review (allowed for 24 hours).
  Future<void> editReview(String reviewId, {double? rating, String? comment}) async {
    final response = await _api.patch(
      '${ApiConstants.reviews}/$reviewId',
      data: {
        if (rating != null) 'rating': rating.round(),
        if (comment != null) 'comment': comment,
      },
    );
    if (!response.success) throw Exception(response.message ?? 'Failed to edit review');
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
