import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:get/get.dart';

class WalletService extends GetxService {
  late final ApiClient _api;

  WalletService() {
    _api = Get.find<ApiClient>();
  }

  Future<Map<String, dynamic>> getWalletBalance() async {
    final response = await _api.get(
      ApiConstants.walletBalance,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return {'balance': 0.0, 'currency': 'MAD', 'transactions': []};
  }

  Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConstants.walletTransactions,
      queryParameters: {'page': page, 'limit': limit},
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return {'docs': <dynamic>[], 'total': 0, 'page': page, 'limit': limit};
  }

  Future<Map<String, dynamic>> topupWallet(double amount) async {
    final response = await _api.post(
      ApiConstants.walletTopup,
      data: {'amount': amount},
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(response.message ?? 'Failed to initialize wallet top-up');
  }
}
