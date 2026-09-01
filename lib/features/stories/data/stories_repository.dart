import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/story_model.dart';
import '../../../core/network/api_client.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepository(ref.read(apiClientProvider).dio);
});

class StoriesRepository {
  final Dio _dio;

  StoriesRepository(this._dio);

  Future<List<StoryModel>> getPendingStories() async {
    final response = await _dio.get('/api/admin/stories', queryParameters: {'verification_status': 'pending'});
    final items = response.data['items'] as List;
    return items.map((e) {
      if (e['id'] != null) e['storyId'] = e['id'];
      if (e['userId'] != null) e['authorId'] = e['userId'];
      return StoryModel.fromMap(e as Map<String, dynamic>, e['storyId'] ?? '');
    }).toList();
  }

  Future<StoryModel?> getStory(String storyId) async {
    try {
      final response = await _dio.get('/api/stories/$storyId');
      final data = response.data as Map<String, dynamic>;
      if (data['id'] != null) data['storyId'] = data['id'];
      if (data['userId'] != null) data['authorId'] = data['userId'];
      return StoryModel.fromMap(data, data['storyId'] ?? storyId);
    } catch (e) {
      return null;
    }
  }

  Future<List<StoryModel>> getStoriesByAuthor(String authorId) async {
    final response = await _dio.get('/api/users/$authorId/stories');
    final items = response.data['items'] as List;
    return items.map((e) {
      if (e['id'] != null) e['storyId'] = e['id'];
      if (e['userId'] != null) e['authorId'] = e['userId'];
      return StoryModel.fromMap(e as Map<String, dynamic>, e['storyId'] ?? '');
    }).toList();
  }

  Future<void> updateStoryVerification(String storyId, String status, String adminId) async {
    if (status == 'verified') {
      await _dio.post('/api/admin/stories/$storyId/verify');
    }
  }

  Future<void> hideStory(String storyId) async {
    await _dio.delete('/api/admin/stories/$storyId');
  }

  Future<void> deleteStory(String storyId) async {
    await _dio.delete('/api/admin/stories/$storyId');
  }
}
