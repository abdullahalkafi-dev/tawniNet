import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:get/get.dart';

class SupportService extends GetxService {
  late final ApiClient _api;

  Future<SupportService> init() async {
    _api = Get.find<ApiClient>();
    return this;
  }

  Future<Map<String, dynamic>> createTicket(String subject, String message) async {
    final response = await _api.post(
      ApiConstants.supportTickets,
      data: {
        'subject': subject,
        'message': message,
      },
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to create support ticket');
  }

  Future<List<dynamic>> getUserTickets() async {
    final response = await _api.get(
      ApiConstants.supportTickets,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    final endpoint = '${ApiConstants.supportTickets}/$ticketId';
    final response = await _api.get(
      endpoint,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to fetch ticket details');
  }

  Future<Map<String, dynamic>> sendSupportMessage(String ticketId, String content) async {
    final endpoint = '${ApiConstants.supportTickets}/$ticketId/messages';
    final response = await _api.post(
      endpoint,
      data: {'content': content},
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to send message');
  }

  Future<Map<String, dynamic>> sendSupportMessageWithImages(
      String ticketId, String content, List<String> imageKeys) async {
    final endpoint = '${ApiConstants.supportTickets}/$ticketId/messages';
    final response = await _api.post(
      endpoint,
      data: {
        'content': content,
        'attachments': imageKeys,
      },
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to send message');
  }
}
