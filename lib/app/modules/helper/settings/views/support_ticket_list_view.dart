import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/modules/helper/settings/controllers/customer_service_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Multi-ticket inbox: list all support tickets with status filter.
/// User taps a ticket to open its chat. Resolved tickets open read-only.
class SupportTicketListView extends StatefulWidget {
  const SupportTicketListView({super.key});

  @override
  State<SupportTicketListView> createState() => _SupportTicketListViewState();
}

class _SupportTicketListViewState extends State<SupportTicketListView> {
  late final CustomerServiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CustomerServiceController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchTickets();
      final args = Get.arguments;
      String? ticketId;
      if (args is Map) {
        ticketId = args['ticketId']?.toString();
      } else if (args is String) {
        ticketId = args;
      }
      if (ticketId != null && ticketId.isNotEmpty) {
        _controller.selectTicket(ticketId).then((_) {
          if (mounted) _openChat();
        });
      }
    });
  }

  void _openChat() {
    final isHelper = _controller.isHelper;
    Get.toNamed(isHelper ? Routes.customerService : Routes.userCustomerService);
  }

  String _formatTime(dynamic updatedAt) {
    if (updatedAt == null) return '';
    try {
      final date = DateTime.parse(updatedAt.toString());
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green.shade400;
      case 'in_progress':
        return Colors.orange.shade400;
      case 'resolved':
        return context.textSecondaryColor;
      default:
        return Colors.blue.shade400;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'all':
        return 'All';
      default:
        return status;
    }
  }

  void _showFilterSheet() {
    const options = [
      ('open', 'Open'),
      ('in_progress', 'In Progress'),
      ('resolved', 'Resolved'),
      ('all', 'All'),
    ];
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Filter by status',
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              for (final option in options)
                Obx(() {
                  final value = option.$1;
                  final label = option.$2;
                  final selected = _controller.statusFilter.value == value;
                  return ListTile(
                    dense: true,
                    title: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : context.textPrimaryColor,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      _controller.statusFilter.value = value;
                      Get.back();
                    },
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewTicketDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.cardColor,
        title: Text(
          'New Support Ticket',
          style: AppStyles.h2Of(dialogCtx).copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              style: TextStyle(color: dialogCtx.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Subject (e.g. Payment issue, Job #12)',
                hintStyle: TextStyle(color: dialogCtx.textHintColor),
                filled: true,
                fillColor: dialogCtx.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogCtx.borderSecondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogCtx.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: TextStyle(color: dialogCtx.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                hintStyle: TextStyle(color: dialogCtx.textHintColor),
                filled: true,
                fillColor: dialogCtx.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogCtx.borderSecondary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: dialogCtx.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: dialogCtx.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();
              if (subject.isNotEmpty && message.isNotEmpty) {
                Navigator.pop(dialogCtx);
                _controller.createTicketAndSend(subject, message).then((_) {
                  if (mounted) _openChat();
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Support',
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            final label = _statusLabel(_controller.statusFilter.value);
            return TextButton.icon(
              onPressed: _showFilterSheet,
              icon: Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              label: Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewTicketDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.tickets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final tickets = _controller.filteredTickets;

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent,
                    size: 64, color: AppColors.primary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  _controller.statusFilter.value == 'all'
                      ? 'No support tickets yet.'
                      : 'No ${_statusLabel(_controller.statusFilter.value).toLowerCase()} tickets.',
                  style: AppStyles.bodyMediumOf(context)
                      .copyWith(color: context.textSecondaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create a new ticket.',
                  style: AppStyles.bodySmallOf(context)
                      .copyWith(color: context.textHintColor, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showFilterSheet,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Change filter'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.fetchTickets(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final id = (ticket['id'] ?? ticket['_id']).toString();
              final subject =
                  (ticket['subject'] ?? 'Support Inquiry').toString();
              final lastMessage = (ticket['lastMessage'] ?? '').toString();
              final status = (ticket['status'] ?? 'open').toString();
              final updatedAt = ticket['updatedAt'];
              final unreadByUser = ticket['unreadByUser'] == true;
              final resolved = status == 'resolved';

              return GestureDetector(
                onTap: () async {
                  await _controller.selectTicket(id);
                  if (context.mounted) {
                    _openChat();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: AppStyles.bodyLargeOf(context)
                                        .copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (unreadByUser)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (lastMessage.isNotEmpty)
                              Text(
                                lastMessage,
                                style:
                                    AppStyles.bodyMediumOf(context).copyWith(
                                  color: context.textSecondaryColor,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (resolved) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Read-only · Create a new ticket for another issue',
                                style: AppStyles.bodySmallOf(context).copyWith(
                                  color: context.textHintColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(updatedAt),
                            style: AppStyles.bodySmallOf(context).copyWith(
                              fontSize: 12,
                              color: context.textHintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
