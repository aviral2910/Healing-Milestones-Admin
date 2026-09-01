import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.read(apiClientProvider).dio);
});

class UsersRepository {
  final Dio _dio;

  UsersRepository(this._dio);

  Future<int> getTotalUsersCount() async {
    final response = await _dio.get('/api/admin/users', queryParameters: {'limit': 1});
    return response.data['total'] as int;
  }

  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get('/api/admin/users');
    final items = response.data['items'] as List;
    return items.map((e) {
      if (e['id'] != null) e['userId'] = e['id']; // map fastAPI id to userId
      return UserModel.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<UserModel?> getUser(String userId) async {
    final response = await _dio.get('/api/users/$userId');
    final data = response.data as Map<String, dynamic>;
    if (data['id'] != null) data['userId'] = data['id'];
    return UserModel.fromMap(data);
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    await _dio.patch('/api/admin/users/$userId/status', data: {'status': newStatus});
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    // Note: The FastAPI backend currently handles role updates during verification 
    // or via a generic patch. We'll send it to a generic user update.
    await _dio.patch('/api/users/$userId', data: {'role': newRole});
  }

  Future<void> updateUserVerification(String userId, bool isVerified) async {
    await _dio.patch('/api/admin/users/$userId/verify', data: {'approve': isVerified});
  }

  Future<List<UserModel>> getAdminRequests() async {
    final response = await _dio.get('/api/admin/verifications');
    final items = response.data['items'] as List;
    return items.map((e) {
      if (e['id'] != null) e['userId'] = e['id'];
      return UserModel.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<void> updateUserAdminAccess(String userId, bool approve) async {
    // Fast api verification handles professional verification, 
    // for admin access we can use the same or a dedicated endpoint.
    // For now we map this to the verify endpoint.
    await _dio.patch('/api/admin/users/$userId/verify', data: {'approve': approve});
  }
}
