import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(FirebaseFirestore.instance);
});

class UsersRepository {
  final FirebaseFirestore _firestore;

  UsersRepository(this._firestore);

  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    await _firestore.collection('users').doc(userId).update({'status': newStatus});
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }

  Future<void> updateUserVerification(String userId, bool isVerified) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': isVerified,
      'appliedForVerification': false,
    });
  }

  Stream<List<UserModel>> getAdminRequests() {
    return _firestore
        .collection('users')
        .where('appliedForAdmin', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateUserAdminAccess(String userId, bool approve) async {
    final updates = <String, dynamic>{
      'appliedForAdmin': false,
    };
    if (approve) {
      updates['role'] = 'admin';
    }
    await _firestore.collection('users').doc(userId).update(updates);
  }
}
