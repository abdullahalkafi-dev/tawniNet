import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/constants/app_info.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/services/api_client.dart';

/// Terms of Service / Privacy Policy, in the app language, as written in the admin dashboard.
class LegalView extends StatefulWidget {
  /// `terms` or `privacy`.
  final String kind;
  const LegalView({super.key, required this.kind});

  @override
  State<LegalView> createState() => _LegalViewState();
}

class _LegalViewState extends State<LegalView> {
  String _content = '';
  bool _isLoading = true;
  bool _failed = false;

  bool get _isTerms => widget.kind == 'terms';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    try {
      final res = await Get.find<ApiClient>().get(
        ApiConstants.legal,
        queryParameters: {'lang': Get.locale?.languageCode ?? 'fr'},
      );
      if (res.success && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        _content = (data[_isTerms ? 'termsOfService' : 'privacyPolicy'] ?? '').toString();
      }
    } catch (_) {
      _failed = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackKey = _isTerms ? 'legal_terms_fallback' : 'legal_privacy_fallback';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _isTerms ? 'legal_terms_title'.tr : 'profile_privacy'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const DetailSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_failed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'err_http_unknown'.tr,
                          style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                        ),
                      ),
                    Text(
                      _content.isEmpty
                          ? fallbackKey.trParams({'email': AppInfo.supportEmail})
                          : _content,
                      style: AppStyles.bodyMediumOf(context).copyWith(
                        height: 1.6,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
