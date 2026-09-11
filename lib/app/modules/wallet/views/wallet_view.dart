import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/api_client.dart';

/// Client wallet: balance + paginated transaction history + top-up entry.
class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final ApiClient _api = Get.find<ApiClient>();
  final ScrollController _scroll = ScrollController();

  double _balance = 0;
  String _currency = 'MAD';
  final List<dynamic> _txs = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bal = await _api.get<dynamic>(
        ApiConstants.walletBalance,
        fromData: (d) => d,
      );
      if (bal.success && bal.data is Map) {
        final map = Map<String, dynamic>.from(bal.data as Map);
        _balance = (map['balance'] ?? 0).toDouble();
        _currency = (map['currency'] ?? 'MAD').toString();
      }

      final hist = await _api.get<dynamic>(
        ApiConstants.walletTransactions,
        queryParameters: {'page': 1, 'limit': 20},
        fromData: (d) => d,
      );
      if (hist.success && hist.data is Map) {
        final map = Map<String, dynamic>.from(hist.data as Map);
        final docs = (map['docs'] as List?) ?? [];
        _txs
          ..clear()
          ..addAll(docs);
        final total = (map['total'] ?? 0) as num;
        _page = 1;
        _hasMore = _txs.length < total;
      }
    } catch (e) {
      AppFeedback.error('Failed to load wallet');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final hist = await _api.get<dynamic>(
        ApiConstants.walletTransactions,
        queryParameters: {'page': next, 'limit': 20},
        fromData: (d) => d,
      );
      if (hist.success && hist.data is Map) {
        final map = Map<String, dynamic>.from(hist.data as Map);
        final docs = (map['docs'] as List?) ?? [];
        _txs.addAll(docs);
        _page = next;
        final total = (map['total'] ?? 0) as num;
        _hasMore = _txs.length < total;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _topUp() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top up wallet'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (MAD)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;

    try {
      final res = await _api.post<dynamic>(
        ApiConstants.walletTopup,
        data: {'amount': amount},
        fromData: (d) => d,
      );
      if (res.success && res.data is Map) {
        final url = (res.data as Map)['checkoutUrl']?.toString();
        if (url != null && url.isNotEmpty) {
          AppFeedback.info('Opening payment...', title: 'Top-up');
          // Open checkout in external browser / webview via url_launcher if wired
        } else {
          AppFeedback.success('Top-up started');
        }
      } else {
        AppFeedback.error(res.message ?? 'Top-up failed');
      }
    } catch (e) {
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Wallet', style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_outlined, color: AppColors.primary),
            onPressed: _topUp,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available balance',
                          style: AppStyles.bodyMedium.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_balance.toStringAsFixed(2)} $_currency',
                          style: AppStyles.h1Of(context).copyWith(
                                color: Colors.white,
                                fontSize: 32,
                              ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _topUp,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F766E),
                          ),
                          child: const Text('Top up'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Transactions', style: AppStyles.h2Of(context)),
                  const SizedBox(height: 8),
                  if (_txs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                        ),
                      ),
                    )
                  else
                    ..._txs.map((t) {
                      final map = Map<String, dynamic>.from(t as Map);
                      final amount = (map['amount'] ?? 0).toDouble();
                      final isCredit = amount >= 0;
                      final desc = (map['description'] ?? map['type'] ?? '').toString();
                      final when = (map['createdAt'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit
                                ? const Color(0xFFE6F7F5)
                                : const Color(0xFFFFF7E6),
                            child: Icon(
                              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isCredit ? const Color(0xFF0D9488) : const Color(0xFFD97706),
                              size: 18,
                            ),
                          ),
                          title: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            when.length >= 16 ? when.substring(0, 16).replaceFirst('T', ' ') : when,
                            style: AppStyles.bodyMedium.copyWith(
                              fontSize: 12,
                              color: context.textHintColor,
                            ),
                          ),
                          trailing: Text(
                            '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCredit ? const Color(0xFF0F766E) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (_loadingMore)
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
