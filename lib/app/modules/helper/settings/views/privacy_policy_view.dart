import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get(ApiConstants.legal);
      if (res.success && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        _content = (data['privacyPolicy'] ?? '').toString();
      }
    } catch (_) {
      _content = '';
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Privacy Policy',
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Text(
                  _content.isEmpty
                      ? 'Privacy policy will appear here once published by the admin.'
                      : _content,
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    height: 1.6,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
    );
  }
}
