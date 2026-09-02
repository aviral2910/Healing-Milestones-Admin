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

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);

    return Scaffold(
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
                controller: _tabController,
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
        body: TabBarView(
        controller: _tabController,
        children: const [
          _PendingProfilesTab(),
          _PendingStoriesTab(),
        ],
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
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141418), // Deep elegant card color
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.push(AppRoutes.userDetail(user.userId, mode: 'verify'));
                  },
                  borderRadius: BorderRadius.circular(24),
                  highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                  splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Big Premium Squircle Avatar
                            Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: const Color(0xFF1E1E24),
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                                image: user.profilePicture != null && user.profilePicture!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(user.profilePicture!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: user.profilePicture == null || user.profilePicture!.isEmpty
                                  ? Icon(Icons.person_rounded, color: theme.colorScheme.primary.withValues(alpha: 0.8), size: 36)
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.alternate_email_rounded, color: Colors.white.withValues(alpha: 0.4), size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          user.username != null ? user.username! : 'No username',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (user.specialty != null && user.specialty!.isNotEmpty) 
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        user.specialty!,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Icon(Icons.mail_outline_rounded, color: Colors.white.withValues(alpha: 0.4), size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user.email,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.5),
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, thickness: 1),
                      
                      // Action Row (Application Ticket Style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.assignment_ind_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "Verification Request",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'REVIEW',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
