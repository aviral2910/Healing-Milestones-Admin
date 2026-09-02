import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardRepository {
  final ApiClient _apiClient;
  DashboardRepository(this._apiClient);

  Future<Map<String, dynamic>> getDashboardQueues() async {
    final response = await _apiClient.dio.get('/api/admin/dashboard/queues');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGrowthTotals() async {
    final response = await _apiClient.dio.get('/api/admin/dashboard/growth-totals');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEngagementHistory() async {
    final response = await _apiClient.dio.get('/api/admin/dashboard/engagement-history');
    return response.data as Map<String, dynamic>;
  }
}
