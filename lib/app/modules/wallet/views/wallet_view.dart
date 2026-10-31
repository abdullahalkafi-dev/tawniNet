import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/widgets/error_retry.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';

/// Client wallet: balance + paginated transaction history + top-up entry.
class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final ApiClient _api = Get.find<ApiClient>();
  final ScrollController _scroll = ScrollController();

  static const _minTopUp = 20;
  static const _maxTopUp = 10000;

  double _balance = 0;
  String _currency = 'MAD';
  final List<dynamic> _txs = [];
  bool _loading = true;
  bool _failed = false;
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
    // Skeleton only the first time; later refreshes keep the numbers on screen.
    setState(() {
      _loading = _txs.isEmpty && _balance == 0;
      _failed = false;
    });
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
      _failed = true;
      if (_txs.isNotEmpty || _balance != 0) AppFeedback.error('ui_failed_to_load_wallet'.tr);
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
        title: Text('ui_top_up_wallet'.tr),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'ui_amount_mad'.tr,
            helperText: 'wallet_topup_range'.trParams({'min': '$_minTopUp', 'max': '$_maxTopUp'}),
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('btn_cancel'.tr)),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (v == null || v < _minTopUp || v > _maxTopUp) {
                AppFeedback.error('wallet_topup_range'.trParams({'min': '$_minTopUp', 'max': '$_maxTopUp'}));
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: Text('ui_continue'.tr),
          ),
        ],
      ),
    );
    if (amount == null) return;

    try {
      final res = await _api.post<dynamic>(
        ApiConstants.walletTopup,
        data: {'amount': amount},
        fromData: (d) => d,
      );
      if (res.success && res.data is Map) {
        final data = res.data as Map;
        final checkoutUrl = data['checkoutUrl']?.toString();
        final sessionId = data['sessionId']?.toString() ?? '';
        final orderId = data['orderId']?.toString() ?? sessionId;

        final paid = await Get.toNamed(
          Routes.checkout,
          arguments: {
            'orderId': orderId,
            'orderType': 'wallet_topup',
            'amount': amount,
            'currency': 'MAD',
            'title': 'ui_top_up_wallet'.tr,
            'sessionId': sessionId,
            'metadata': {
              'userId': Get.find<AuthService>().currentUser.value?.id,
              'orderId': orderId,
              if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
            },
          },
        );

        if (paid == true) {
          AppFeedback.success('ui_wallet_topped_up_successfully'.tr);
          _load();
        }
      } else {
        AppFeedback.error(res.message ?? 'ui_top_up_failed'.tr);
      }
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('ui_wallet'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
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
          ? const _WalletSkeleton()
          : (_failed && _txs.isEmpty && _balance == 0)
              ? ErrorRetry(onRetry: _load)
              : RefreshIndicator(
              onRefresh: _load,
              displacement: 20,
              edgeOffset: 24,
              color: AppColors.primary,
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
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
                          'ui_available_balance'.tr,
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
                          child: Text('ui_top_up'.tr),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('ui_transactions'.tr, style: AppStyles.h2Of(context)),
                  const SizedBox(height: 8),
                  if (_txs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'ui_no_transactions_yet'.tr,
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
                      final whenDate = DateTime.tryParse((map['createdAt'] ?? '').toString())?.toLocal();
                      final when = whenDate == null
                          ? ''
                          : '${AppDateTime.toIsoDate(whenDate)} ${AppDateTime.clockTime(whenDate.toIso8601String())}';
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
                            when,
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

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SkeletonBox(width: double.infinity, height: 130, radius: 16),
          const SizedBox(height: 24),
          const SkeletonLine(height: 16, widthFactor: 0.35),
          const SizedBox(height: 12),
          for (var i = 0; i < 5; i++) ...[
            const Row(
              children: [
                SkeletonCircle(size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(height: 12, widthFactor: 0.6),
                      SizedBox(height: 8),
                      SkeletonLine(height: 10, widthFactor: 0.3),
                    ],
                  ),
                ),
                SkeletonBox(width: 50, height: 14, radius: 6),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
