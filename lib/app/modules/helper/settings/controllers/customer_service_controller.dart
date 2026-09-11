import 'dart:async';

import 'package:awnneaapp/app/services/support_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:get/get.dart';

class CustomerServiceController extends GetxController {
  final tickets = <dynamic>[].obs;
  final messages = <dynamic>[].obs;
  final selectedTicketId = ''.obs;
  final selectedTicketStatus = 'open'.obs;
  final statusFilter = 'open'.obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  late final SocketService _socketService;
  StreamSubscription<Map<String, dynamic>>? _supportSub;

  bool get isResolved => selectedTicketStatus.value == 'resolved';
  bool get canSend => selectedTicketId.value.isNotEmpty && !isResolved;

  List<dynamic> get filteredTickets {
    final f = statusFilter.value;
    if (f == 'all') return tickets;
    return tickets
        .where((t) => (t['status'] ?? 'open').toString() == f)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _socketService = Get.find<SocketService>();
    fetchTickets();
    _listenSocket();
  }

  @override
  void onClose() {
    if (selectedTicketId.value.isNotEmpty) {
      _socketService.leaveSupportRoom(selectedTicketId.value);
    }
    _supportSub?.cancel();
    _supportSub = null;
    super.onClose();
  }

  void _listenSocket() {
    _supportSub?.cancel();
    _supportSub = _socketService.onSupportMessage.listen((data) {
      if (isClosed) return;
      final ticketId = data['ticketId']?.toString() ?? '';
      final msg = data['message'] ?? data;
      if (msg is! Map) return;
      final msgId = (msg['_id'] ?? msg['id'])?.toString();
      final content = (msg['content'] ?? '').toString();
      final preview = content.isNotEmpty ? content : '📎 Attachment';

      // Update list for ANY ticket (selected or not)
      if (ticketId.isNotEmpty) {
        final idx = tickets.indexWhere(
          (t) => (t['_id'] ?? t['id']).toString() == ticketId,
        );
        if (idx >= 0) {
          final isAdmin = msg['senderRole'] == 'admin';
          final wasUnread = tickets[idx]['unreadByUser'] == true;
          tickets[idx] = {
            ...Map<String, dynamic>.from(tickets[idx] as Map),
            'lastMessage': preview,
            'updatedAt': DateTime.now().toIso8601String(),
            if (ticketId != selectedTicketId.value && isAdmin)
              'unreadByUser': true
            else if (ticketId == selectedTicketId.value)
              'unreadByUser': false
            else
              'unreadByUser': wasUnread,
          };
        }
      }

      // Append only for the open thread
      if (ticketId == selectedTicketId.value) {
        _appendMessageIfNew(msg, msgId);
      }
    });
  }

  void _appendMessageIfNew(Map msg, String? msgId) {
    if (msgId != null && msgId.isNotEmpty) {
      final exists = messages.any(
        (m) => (m['_id'] ?? m['id'])?.toString() == msgId,
      );
      if (exists) return;
    }
    messages.add(msg);
  }

  Future<void> fetchTickets() async {
    isLoading.value = true;
    try {
      final supportService = Get.find<SupportService>();
      final list = await supportService.getUserTickets();
      tickets.assignAll(list);
      // Do NOT auto-select — user picks from the list.
      // If a ticket is already selected, refresh its status badge.
      if (selectedTicketId.value.isNotEmpty) {
        final match = tickets.firstWhereOrNull(
          (t) => (t['_id'] ?? t['id']).toString() == selectedTicketId.value,
        );
        if (match != null) {
          selectedTicketStatus.value =
              (match['status'] ?? 'open').toString();
        }
      }
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error('Failed to load tickets');
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> selectTicket(String ticketId) async {
    if (selectedTicketId.value.isNotEmpty &&
        selectedTicketId.value != ticketId) {
      _socketService.leaveSupportRoom(selectedTicketId.value);
    }

    selectedTicketId.value = ticketId;
    messages.clear();

    // Find status from list first for instant UI
    final match = tickets.firstWhereOrNull(
      (t) => (t['_id'] ?? t['id']).toString() == ticketId,
    );
    selectedTicketStatus.value =
        (match?['status'] ?? 'open').toString();

    _socketService.joinSupportRoom(ticketId);

    // Clear unread on this ticket
    if (match != null && match['unreadByUser'] == true) {
      final idx = tickets.indexOf(match);
      if (idx >= 0) {
        tickets[idx] = {
          ...Map<String, dynamic>.from(match as Map),
          'unreadByUser': false,
        };
      }
    }

    try {
      final supportService = Get.find<SupportService>();
      final details = await supportService.getTicketDetails(ticketId);
      final ticket = details['ticket'];
      if (ticket is Map) {
        selectedTicketStatus.value =
            (ticket['status'] ?? selectedTicketStatus.value).toString();
      }
      final msgs = details['messages'] as List? ?? [];
      messages.assignAll(msgs);
      // Refresh list so status/unread stay in sync
      unawaited(fetchTickets());
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error('Failed to load messages');
      }
    }
  }

  void clearSelection() {
    if (selectedTicketId.value.isNotEmpty) {
      _socketService.leaveSupportRoom(selectedTicketId.value);
    }
    selectedTicketId.value = '';
    selectedTicketStatus.value = 'open';
    messages.clear();
  }

  Future<void> createTicketAndSend(String subject, String text) async {
    try {
      final supportService = Get.find<SupportService>();
      final res = await supportService.createTicket(subject, text);
      final id =
          (res['id'] ?? res['_id'] ?? res['ticket']?['_id'])?.toString() ?? '';
      if (id.isNotEmpty) {
        await fetchTickets();
        await selectTicket(id);
      }
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> sendMessage(String text, {List<String> attachments = const []}) async {
    if (!canSend) {
      if (isResolved) {
        AppFeedback.error(
          'This ticket is resolved. Create a new ticket for a new issue.',
        );
      }
      return;
    }
    if (text.trim().isEmpty && attachments.isEmpty) return;
    isSending.value = true;
    try {
      final supportService = Get.find<SupportService>();
      Map<String, dynamic> msg;
      if (attachments.isNotEmpty) {
        msg = await supportService.sendSupportMessageWithImages(
          selectedTicketId.value,
          text.trim(),
          attachments,
        );
      } else {
        msg = await supportService.sendSupportMessage(
          selectedTicketId.value,
          text.trim(),
        );
      }
      _appendMessageIfNew(msg, (msg['_id'] ?? msg['id'])?.toString());
      _touchListPreview(msg);
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }

  Future<void> sendImageMessage(List<String> keys) async {
    if (!canSend || keys.isEmpty) return;
    isSending.value = true;
    try {
      final supportService = Get.find<SupportService>();
      final msg = await supportService.sendSupportMessageWithImages(
        selectedTicketId.value,
        '',
        keys,
      );
      _appendMessageIfNew(msg, (msg['_id'] ?? msg['id'])?.toString());
      _touchListPreview(msg);
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }

  void _touchListPreview(Map msg) {
    final ticketId = selectedTicketId.value;
    final idx = tickets.indexWhere(
      (t) => (t['_id'] ?? t['id']).toString() == ticketId,
    );
    if (idx < 0) return;
    final content = (msg['content'] ?? '').toString();
    tickets[idx] = {
      ...Map<String, dynamic>.from(tickets[idx] as Map),
      'lastMessage': content.isNotEmpty ? content : '📎 Attachment',
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  bool get isHelper =>
      Get.isRegistered<RoleService>() && Get.find<RoleService>().role == 'helper';
}
