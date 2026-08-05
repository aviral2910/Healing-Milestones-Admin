import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/report_model.dart';
import '../../../../core/models/story_model.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(FirebaseFirestore.instance);
});

class ModerationRepository {
  final FirebaseFirestore _firestore;

  ModerationRepository(this._firestore);

  Stream<List<ReportModel>> getPendingReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<StoryModel?> getStory(String storyId) async {
    final doc = await _firestore.collection('stories').doc(storyId).get();
    if (!doc.exists) return null;
    return StoryModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> resolveReport(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({'status': status});
  }

  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }

  Future<void> hideStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).update({'isHidden': true});
  }
}
