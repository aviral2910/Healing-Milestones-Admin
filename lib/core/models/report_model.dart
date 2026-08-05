import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String storyId;
  final String reporterId;
  final String reason;
  final String status;
  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.storyId,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReportModel(
      reportId: documentId,
      storyId: map['storyId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
