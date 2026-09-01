import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/stories_repository.dart';
import '../../../users/data/users_repository.dart';
import '../../../../core/presentation/widgets/admin_confirmation_dialog.dart';
import '../../../../core/models/story_model.dart';

// Provider to fetch a single story
final singleStoryProvider = FutureProvider.family<StoryModel?, String>((ref, storyId) {
  return ref.watch(storiesRepositoryProvider).getStory(storyId);
});

class StoryDetailScreen extends ConsumerWidget {
  final String storyId;
  final String mode; // 'manage' or 'verify'

  const StoryDetailScreen({
    super.key,
    required this.storyId,
    this.mode = 'manage',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storyAsync = ref.watch(singleStoryProvider(storyId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Story Details'),
      ),
      body: storyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (story) {
          if (story == null) {
            return const Center(child: Text('Story not found', style: TextStyle(color: Colors.white)));
          }

          final hasImage = story.mainImage.isNotEmpty;

          return CustomScrollView(
            slivers: [
              // Admin Controls Bar
              SliverToBoxAdapter(
                child: _StoryAdminControlsBar(story: story, mode: mode),
              ),
              // Cover Image Hero
              if (hasImage)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(story.mainImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.heading,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Author Badge
                      InkWell(
                        onTap: () => context.push(AppRoutes.userDetail(story.authorId, mode: mode)),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, color: theme.colorScheme.primary, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'View Author Profile',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Likes and Comments row
                      Row(
                        children: [
                          Icon(Icons.thumb_up, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${story.likesCount} Likes',
                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 24),
                          Icon(Icons.comment, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${story.commentCount} Comments',
                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: theme.colorScheme.primary.withAlpha(40), thickness: 1),
                      const SizedBox(height: 24),
                      Text(
                        story.description,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryAdminControlsBar extends ConsumerWidget {
  final StoryModel story;
  final String mode;

  const _StoryAdminControlsBar({required this.story, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesRepo = ref.watch(storiesRepositoryProvider);

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(bottom: BorderSide(color: theme.colorScheme.primary.withAlpha(50), width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: mode == 'verify' && !story.isVerifiedStory && story.verificationStatus == 'pending'
          ? Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary, // Premium Gold
                      foregroundColor: Colors.black, // Dark text on gold
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve Story'),
                    onPressed: () async {
                      final confirm = await showAdminConfirmationDialog(
                        context: context,
                        title: 'Approve Story',
                        content: 'Are you sure you want to approve this story for publication?',
                        confirmText: 'Approve',
                      );
                      if (confirm != true) return;

                      try {
                        final adminId = 'admin'; // TODO get actual admin ID
                        await storiesRepo.updateStoryVerification(story.storyId, 'verified', adminId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Story verified!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject Story'),
                    onPressed: () async {
                      final confirm = await showAdminConfirmationDialog(
                        context: context,
                        title: 'Reject Story',
                        content: 'Are you sure you want to reject this story?',
                        confirmText: 'Reject',
                        isDestructive: true,
                      );
                      if (confirm != true) return;

                      try {
                        final adminId = 'admin'; // TODO get actual admin ID
                        await storiesRepo.updateStoryVerification(story.storyId, 'rejected', adminId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Story rejected.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!story.isHidden)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.visibility_off),
                    label: const Text('Hide Story'),
                    onPressed: () async {
                      final confirm = await showAdminConfirmationDialog(
                        context: context,
                        title: 'Hide Story',
                        content: 'Are you sure you want to hide this story? It will only be visible to its owner.',
                        confirmText: 'Hide',
                        isDestructive: false,
                      );
                      if (confirm != true) return;

                      try {
                        await storiesRepo.hideStory(story.storyId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Story hidden.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                if (!story.isHidden) const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Story'),
                  onPressed: () async {
                    final confirm = await showAdminConfirmationDialog(
                      context: context,
                      title: 'Delete Story',
                      content: 'Are you sure you want to permanently delete this story?',
                      confirmText: 'Delete',
                      isDestructive: true,
                    );
                    if (confirm != true) return;

                    try {
                      await storiesRepo.deleteStory(story.storyId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Story deleted.')),
                        );
                        context.pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
    );
  }
}
