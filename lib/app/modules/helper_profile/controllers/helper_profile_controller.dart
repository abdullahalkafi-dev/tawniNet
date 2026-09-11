import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/review_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';

class HelperProfileController extends GetxController {
  final helper = Rxn<HelperProfileData>();
  final isLoading = false.obs;
  final reviews = <Map<String, dynamic>>[].obs;
  final isLoadingReviews = false.obs;
  final messageController = TextEditingController();

  String? _helperId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String) {
      _helperId = args;
      fetchHelperProfile(args);
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  Future<void> fetchHelperProfile(String id) async {
    isLoading.value = true;
    try {
      final api = Get.find<ApiClient>();
      final response = await api.get<Map<String, dynamic>>(
        ApiConstants.helperProfileById(id),
      );

      if (response.success && response.data != null) {
        helper.value = HelperProfileData.fromJson(response.data!);
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
    fetchReviews(id);
  }

  Future<void> fetchReviews(String id) async {
    isLoadingReviews.value = true;
    try {
      final reviewService = Get.find<ReviewService>();
      final raw = await reviewService.getUserReviews(id);
      final out = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final reviewer = map['reviewer'];
        String name = 'Client';
        String avatar = '';
        if (reviewer is Map) {
          name = (reviewer['name'] ?? name).toString();
          avatar = (reviewer['avatar'] ?? '').toString();
        }
        final ratingRaw = map['rating'];
        final rating = (ratingRaw is num
                ? ratingRaw
                : (num.tryParse(ratingRaw?.toString() ?? '') ?? 0))
            .toDouble()
            .clamp(0, 5);
        out.add({
          'id': (map['_id'] ?? map['id'] ?? '').toString(),
          'rating': rating,
          'comment': (map['comment'] ?? '').toString(),
          'createdAt': (map['createdAt'] ?? '').toString(),
          'reviewerName': name,
          'reviewerAvatar': avatar,
          'date': AppDateTime.formatDateDisplay(
            (map['createdAt'] ?? '').toString(),
          ),
        });
      }
      reviews.assignAll(out);
    } catch (_) {
      reviews.clear();
    } finally {
      isLoadingReviews.value = false;
    }
  }

  /// Chat button: create conversation → open chat inbox
  Future<void> startChat() async {
    final id = _helperId;
    if (id == null) return;

    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(id);
    if (conversation != null) {
      final other = conversation.otherParticipant;
      Get.toNamed(
        Routes.chatDetail,
        arguments: ChatSummary(
          id: conversation.id,
          name: other?.name ?? helper.value?.name ?? 'Helper',
          image: other?.avatar ?? '',
        ),
      );
    }
  }

  /// Bottom bar: send message → create conversation → send → open inbox
  Future<void> sendMessageAndOpenChat() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final id = _helperId;
    if (id == null) return;

    // 1. Create/get conversation
    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(id);
    if (conversation == null) return;

    // 2. Send the message
    final api = Get.find<ApiClient>();
    await api.post(
      ApiConstants.chatMessages(conversation.id),
      data: {
        'type': 'text',
        'content': text,
      },
    );

    messageController.clear();

    // 3. Open chat inbox
    final other = conversation.otherParticipant;
    Get.toNamed(
      Routes.chatDetail,
      arguments: ChatSummary(
        id: conversation.id,
        name: other?.name ?? helper.value?.name ?? 'Helper',
        image: other?.avatar ?? '',
      ),
    );
  }
}
