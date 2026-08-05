import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healing_milestones_admin/features/users/data/users_repository.dart';
import '../../data/moderation_repository.dart';
import '../../../../core/presentation/widgets/admin_confirmation_dialog.dart';
import '../../../../core/models/report_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/user_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';

final pendingReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(moderationRepositoryProvider).getPendingReports();
});

final storyFutureProvider = FutureProvider.family<StoryModel?, String>((
  ref,
  storyId,
) {
  return ref.watch(moderationRepositoryProvider).getStory(storyId);
});

final userFutureProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final stream = ref.watch(usersRepositoryProvider).getUserStream(userId);
  return await stream.first;
});

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider);
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Content Moderation')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'No pending reports.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(report: report);
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyFutureProvider(report.storyId));
    final reporterAsync = ref.watch(userFutureProvider(report.reporterId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/story/${report.storyId}?mode=manage');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reported for: ${report.reason}',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              reporterAsync.when(
                loading: () => const Text(
                  'Reporter: Loading...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                error: (err, stack) => const Text(
                  'Reporter: Error',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                data: (user) {
                  final username = user?.username != null
                      ? '@${user!.username}'
                      : (user?.displayName ?? 'Unknown User');
                  return Text(
                    'Reported by: $username',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 24),
              storyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Text(
                  'Error loading story: $err',
                  style: const TextStyle(color: Colors.white),
                ),
                data: (story) {
                  if (story == null) {
                    return const Text(
                      'Story not found (may have been deleted)',
                      style: TextStyle(color: Colors.white54),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.heading,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story.shortDescription,
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              // dismiss
                              await ref
                                  .read(moderationRepositoryProvider)
                                  .resolveReport(report.reportId, 'dismissed');
                            },
                            child: const Text(
                              'Dismiss',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () async {
                              final confirm = await showAdminConfirmationDialog(
                                context: context,
                                title: 'Hide Story',
                                content:
                                    'Are you sure you want to hide this story? It will only be visible to its owner.',
                                confirmText: 'Hide',
                                isDestructive: false,
                              );
                              if (confirm != true) return;

                              final repo = ref.read(moderationRepositoryProvider);
                              await repo.hideStory(story.storyId);
                              await repo.resolveReport(report.reportId, 'resolved');
                            },
                            child: const Text(
                              'Hide',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm = await showAdminConfirmationDialog(
                                context: context,
                                title: 'Delete Story',
                                content:
                                    'Are you sure you want to permanently delete this story and resolve the report?',
                                confirmText: 'Delete',
                                isDestructive: true,
                              );
                              if (confirm != true) return;

                              // Delete story and resolve report
                              final repo = ref.read(
                                moderationRepositoryProvider,
                              );
                              await repo.deleteStory(story.storyId);
                              await repo.resolveReport(
                                report.reportId,
                                'resolved',
                              );
                            },
                            child: const Text(
                              'Delete Story',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
