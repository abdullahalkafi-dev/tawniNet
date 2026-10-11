import 'package:flutter/material.dart';
import 'package:awnneaapp/app/modules/helper/settings/views/customer_service_view.dart';

/// Reusable support screen for customer accounts.
/// Delegates directly to [CustomerServiceView] to avoid duplicate logic.
class UserCustomerServiceView extends StatelessWidget {
  const UserCustomerServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerServiceView();
  }
}
