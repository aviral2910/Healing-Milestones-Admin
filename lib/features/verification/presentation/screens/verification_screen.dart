import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:healing_milestones_admin/core/router/app_routes.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../users/data/users_repository.dart';
import '../../../stories/data/stories_repository.dart';
import '../../../../core/presentation/widgets/admin_story_list_tile.dart';

final pendingProfilesProvider = FutureProvider((ref) async {
  return ref.watch(usersRepositoryProvider).getAdminRequests();
});

final pendingStoriesProvider = FutureProvider((ref) {
  return ref.watch(storiesRepositoryProvider).getPendingStories();
});

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Verification Hub',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Profiles'),
                  Tab(text: 'Stories'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingProfilesTab(),
            _PendingStoriesTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingProfilesTab extends ConsumerWidget {
  const _PendingProfilesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(pendingProfilesProvider);
    final theme = Theme.of(context);

    return profilesAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      data: (profiles) {
        if (profiles.isEmpty) {
          return Center(
            child: Text(
              'No pending profiles.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 40),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final user = profiles[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0C), // Ultra deep black
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15), width: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.push(AppRoutes.userDetail(user.userId, mode: 'verify'));
                  },
                  borderRadius: BorderRadius.circular(20),
                  highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                  splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                                ? NetworkImage(user.profilePicture!)
                                : null,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: user.profilePicture == null || user.profilePicture!.isEmpty 
                                ? Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 30) 
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (user.username != null)
                                Text(
                                  '@${user.username}',
                                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Verification badge + arrow
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 12),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.2), size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingStoriesTab extends ConsumerWidget {
  const _PendingStoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(pendingStoriesProvider);
    final theme = Theme.of(context);

    return storiesAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      data: (stories) {
        if (stories.isEmpty) {
          return Center(
            child: Text(
              'No pending stories.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 40),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return AdminStoryListTile(
              story: story,
              onTap: () {
                context.push(AppRoutes.storyDetail(story.storyId, mode: 'verify'));
              },
            );
          },
        );
      },
    );
  }
}
