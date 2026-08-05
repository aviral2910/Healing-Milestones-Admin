import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/story_model.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepository(FirebaseFirestore.instance);
});

class StoriesRepository {
  final FirebaseFirestore _firestore;

  StoriesRepository(this._firestore);

  Stream<List<StoryModel>> getPendingStories() {
    return _firestore
        .collection('stories')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<StoryModel?> getStoryStream(String storyId) {
    return _firestore.collection('stories').doc(storyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return StoryModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<StoryModel>> getStoriesByAuthor(String authorId) {
    return _firestore
        .collection('stories')
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateStoryVerification(String storyId, String status, String adminId) async {
    await _firestore.collection('stories').doc(storyId).update({
      'verificationStatus': status,
      'isVerifiedStory': status == 'verified',
      if (status == 'verified') 'verifiedAt': FieldValue.serverTimestamp(),
      'verifierId': adminId,
    });
  }

  Future<void> hideStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).update({'isHidden': true});
  }

  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }
}
