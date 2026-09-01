import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/report_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../core/network/api_client.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(ref.read(apiClientProvider).dio);
});

class ModerationRepository {
  final Dio _dio;

  ModerationRepository(this._dio);

  Future<List<ReportModel>> getPendingReports() async {
    final response = await _dio.get('/api/admin/reports', queryParameters: {'status': 'pending'});
    final items = response.data['items'] as List;
    return items.map((e) {
      // Create ReportModel from FastAPI dict
      return ReportModel(
        reportId: e['id'] ?? '',
        storyId: e['storyId'] ?? '',
        reporterId: e['reporterId'] ?? '',
        reason: e['reason'] ?? '',
        status: e['status'] ?? 'pending',
        createdAt: DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<StoryModel?> getStory(String storyId) async {
    try {
      final response = await _dio.get('/api/stories/$storyId');
      final data = response.data as Map<String, dynamic>;
      // Map 'id' to 'storyId' if necessary
      if (data['id'] != null) data['storyId'] = data['id'];
      if (data['userId'] != null) data['authorId'] = data['userId'];
      return StoryModel.fromMap(data, data['storyId'] ?? storyId);
    } catch (e) {
      return null;
    }
  }

  Future<void> resolveReport(String reportId, String status) async {
    await _dio.patch('/api/admin/reports/$reportId', data: {'status': status});
  }

  Future<void> deleteStory(String storyId) async {
    await _dio.delete('/api/admin/stories/$storyId');
  }

  Future<void> hideStory(String storyId) async {
    // FastAPI might not have hide yet, so we just delete it or ignore.
    await _dio.delete('/api/admin/stories/$storyId');
  }
}
