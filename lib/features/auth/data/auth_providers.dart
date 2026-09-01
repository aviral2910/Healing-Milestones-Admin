import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final adminClaimProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  
  try {
    final dio = ref.read(apiClientProvider).dio;
    final response = await dio.get('/api/admin/auth/me');
    return response.statusCode == 200;
  } catch (e) {
    print('Admin verification failed: $e');
    return false;
  }
});
