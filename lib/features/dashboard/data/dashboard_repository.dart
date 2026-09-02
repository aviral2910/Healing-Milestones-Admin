import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardRepository {
  final ApiClient _apiClient;
  DashboardRepository(this._apiClient);

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _apiClient.dio.get('/api/admin/dashboard/metrics');
    return response.data as Map<String, dynamic>;
  }
}
