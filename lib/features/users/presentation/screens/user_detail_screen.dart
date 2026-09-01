import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/presentation/widgets/user_profile_header.dart';
import '../../../../core/presentation/widgets/admin_story_list_tile.dart';
import '../../../stories/data/stories_repository.dart';
import '../../data/users_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../../core/presentation/widgets/admin_confirmation_dialog.dart';

// Provider to fetch a single user
final singleUserProvider = FutureProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(usersRepositoryProvider).getUser(userId);
});

// Provider to fetch stories for a user
final userStoriesProvider = FutureProvider.family<List<StoryModel>, String>((ref, userId) {
  return ref.watch(storiesRepositoryProvider).getStoriesByAuthor(userId);
});

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  final String mode; // 'manage' or 'verify'

  const UserDetailScreen({
    super.key,
    required this.userId,
    this.mode = 'manage',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(singleUserProvider(userId));
    final storiesAsync = ref.watch(userStoriesProvider(userId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found', style: TextStyle(color: Colors.white)));
          }

          return CustomScrollView(
            slivers: [
              // Admin Controls Bar
              SliverToBoxAdapter(
                child: _AdminControlsBar(user: user, mode: mode),
              ),
              // Profile Header
              SliverToBoxAdapter(
                child: UserProfileHeader(user: user),
              ),
              // Stories Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Stories by User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Stories List
              storiesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  )),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                ),
                data: (stories) {
                  if (stories.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No stories found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final story = stories[index];
                        return AdminStoryListTile(
                          story: story,
                          onTap: () {
                            context.push(AppRoutes.storyDetail(story.storyId, mode: mode));
                          },
                        );
                      },
                      childCount: stories.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminControlsBar extends ConsumerWidget {
  final UserModel user;
  final String mode;

  const _AdminControlsBar({required this.user, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersRepo = ref.watch(usersRepositoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(bottom: BorderSide(color: theme.colorScheme.primary.withAlpha(50), width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: _buildControls(context, usersRepo, theme),
    );
  }

  Widget _buildControls(BuildContext context, UsersRepository usersRepo, ThemeData theme) {
    if (mode == 'manage_admin' && user.appliedForAdmin) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, // Premium Gold
                foregroundColor: Colors.black, // Dark text on gold
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Grant Admin Access'),
              onPressed: () async {
                final confirm = await showAdminConfirmationDialog(
                  context: context,
                  title: 'Grant Admin Access',
                  content: 'Are you sure you want to grant admin privileges to this user?',
                  confirmText: 'Grant Access',
                );
                if (confirm != true) return;

                try {
                  await usersRepo.updateUserAdminAccess(user.userId, true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin access granted!')),
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
              label: const Text('Reject Request'),
              onPressed: () async {
                final confirm = await showAdminConfirmationDialog(
                  context: context,
                  title: 'Reject Request',
                  content: 'Are you sure you want to reject this admin request?',
                  confirmText: 'Reject',
                  isDestructive: true,
                );
                if (confirm != true) return;

                try {
                  await usersRepo.updateUserAdminAccess(user.userId, false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin request rejected.')),
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
      );
    }

    if (mode == 'verify' && !user.isVerified && user.appliedForVerification) {
      return Row(
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
                    label: const Text('Approve Profile'),
                    onPressed: () async {
                      final confirm = await showAdminConfirmationDialog(
                        context: context,
                        title: 'Approve Profile',
                        content: 'Are you sure you want to verify this profile?',
                        confirmText: 'Approve',
                      );
                      if (confirm != true) return;

                      try {
                        await usersRepo.updateUserVerification(user.userId, true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile verified!')),
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
                    label: const Text('Reject Profile'),
                    onPressed: () async {
                      final confirm = await showAdminConfirmationDialog(
                        context: context,
                        title: 'Reject Profile',
                        content: 'Are you sure you want to reject this profile verification?',
                        confirmText: 'Reject',
                        isDestructive: true,
                      );
                      if (confirm != true) return;

                      try {
                        await usersRepo.updateUserVerification(user.userId, false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification rejected.')),
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
            );
    }

    // Default manage mode
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (user.status == 'banned')
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            icon: const Icon(Icons.undo),
            label: const Text('Unban User'),
            onPressed: () async {
              final confirm = await showAdminConfirmationDialog(
                context: context,
                title: 'Unban User',
                content: 'Are you sure you want to unban this user?',
                confirmText: 'Unban',
              );
              if (confirm != true) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unban action not fully implemented')),
              );
            },
          )
        else
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
            icon: const Icon(Icons.block),
            label: const Text('Ban User'),
            onPressed: () async {
              final confirm = await showAdminConfirmationDialog(
                context: context,
                title: 'Ban User',
                content: 'Are you sure you want to ban this user? They will not be able to access the platform.',
                confirmText: 'Ban',
                isDestructive: true,
              );
              if (confirm != true) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ban action not fully implemented')),
              );
            },
          ),
      ],
    );
  }
}
