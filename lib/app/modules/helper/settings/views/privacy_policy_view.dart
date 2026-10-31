import 'package:awnneaapp/app/modules/common/views/legal_view.dart';
import 'package:flutter/material.dart';

/// Kept for the existing route; the content is shown by [LegalView].
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) => const LegalView(kind: 'privacy');
}
