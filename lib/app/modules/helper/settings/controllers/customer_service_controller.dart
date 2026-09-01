import 'package:awnneaapp/app/services/support_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:get/get.dart';

class CustomerServiceController extends GetxController {
  final tickets = <dynamic>[].obs;
  final messages = <dynamic>[].obs;
  final selectedTicketId = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
    _listenSocket();
  }

  void _listenSocket() {
    try {
      final socketService = Get.find<SocketService>();
      socketService.socket?.on('supportMessage', (data) {
        if (data != null && data['ticketId'] == selectedTicketId.value) {
          messages.add(data['message'] ?? data);
        }
      });
    } catch (_) {}
  }

  Future<void> fetchTickets() async {
    isLoading.value = true;
    try {
      final supportService = Get.find<SupportService>();
      final list = await supportService.getUserTickets();
      tickets.assignAll(list);
      if (tickets.isNotEmpty && selectedTicketId.value.isEmpty) {
        selectTicket((tickets.first['id'] ?? tickets.first['_id']).toString());
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectTicket(String ticketId) async {
    selectedTicketId.value = ticketId;
    try {
      final supportService = Get.find<SupportService>();
      final details = await supportService.getTicketDetails(ticketId);
      messages.assignAll(details['messages'] as List? ?? []);
    } catch (_) {}
  }

  Future<void> createTicketAndSend(String subject, String text) async {
    try {
      final supportService = Get.find<SupportService>();
      final res = await supportService.createTicket(subject, text);
      final id = (res['id'] ?? res['_id'])?.toString() ?? '';
      await fetchTickets();
      if (id.isNotEmpty) {
        selectTicket(id);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (selectedTicketId.value.isEmpty) {
      await createTicketAndSend('Support Inquiry', text);
      return;
    }

    try {
      final supportService = Get.find<SupportService>();
      final res = await supportService.sendSupportMessage(selectedTicketId.value, text);
      messages.add(res['data'] ?? {'content': text, 'senderRole': 'user', 'createdAt': DateTime.now().toIso8601String()});
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
