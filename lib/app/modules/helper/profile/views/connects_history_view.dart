import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ConnectsHistoryView extends StatefulWidget {
  const ConnectsHistoryView({super.key});

  @override
  State<ConnectsHistoryView> createState() => _ConnectsHistoryViewState();
}

class _ConnectsHistoryViewState extends State<ConnectsHistoryView> {
  final ScrollController _scroll = ScrollController();

  double balance = 0.0;
  List<Map<String, dynamic>> topups = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int page = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => isLoading = true);
    try {
      final walletService = Get.find<WalletService>();
      final balRes = await walletService.getWalletBalance();
      final histRes = await walletService.getTransactions(page: 1, limit: 20);

      final docs = (histRes['docs'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((t) => (t['type'] ?? '').toString() == 'topup')
          .toList();
      final total = (histRes['total'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          balance = (balRes['balance'] as num?)?.toDouble() ?? 0.0;
          topups = docs;
          page = 1;
          hasMore = total > 20;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore || !hasMore) return;
    setState(() => isLoadingMore = true);
    try {
      final walletService = Get.find<WalletService>();
      final next = page + 1;
      final histRes = await walletService.getTransactions(page: next, limit: 20);
      final docs = (histRes['docs'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((t) => (t['type'] ?? '').toString() == 'topup')
          .toList();
      final total = (histRes['total'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          topups.addAll(docs);
          page = next;
          hasMore = topups.length < total;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoadingMore = false);
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly == today) return 'Today';
      if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '';
    }
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
          'connects_recharge_history'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'connects_balance'.tr,
                          style: const TextStyle(color: AppColors.primary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MAD ${balance.toStringAsFixed(2)}',
                          style: AppStyles.h1Of(context).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await Get.toNamed(Routes.buyConnects);
                            if (mounted) _fetch();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          child: Text('connects_buy'.tr, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('connects_recharge_history'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (topups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'connects_no_recharges'.tr,
                          style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                        ),
                      ),
                    )
                  else
                    ...topups.map((t) {
                      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
                      final when = _formatDate(t['createdAt']);
                      final desc = (t['description'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE6F7F5),
                            child: Icon(
                              Icons.add_card_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            desc.isNotEmpty ? desc : 'connects_recharge'.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            when,
                            style: AppStyles.bodyMedium.copyWith(
                              fontSize: 12,
                              color: context.textHintColor,
                            ),
                          ),
                          trailing: Text(
                            '+MAD ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      );
                    }),
                  if (isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
            ),
    );
  }
}
