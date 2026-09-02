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
                color: const Color(0xFF0A0A0C), // Deep premium black
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Illuminated watermark background
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.how_to_reg_rounded,
                      size: 140,
                      color: theme.colorScheme.primary.withValues(alpha: 0.03),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.push(AppRoutes.userDetail(user.userId, mode: 'verify'));
                      },
                      borderRadius: BorderRadius.circular(24),
                      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                      splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            // Premium Avatar
                            Container(
                              width: 65,
                              height: 65,
                              padding: const EdgeInsets.all(3), // Inner spacing for ring
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0A0A0C),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                                        ? NetworkImage(user.profilePicture!)
                                        : null,
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                    child: user.profilePicture == null || user.profilePicture!.isEmpty 
                                        ? Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 28) 
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (user.username != null)
                                    Row(
                                      children: [
                                        Icon(Icons.alternate_email_rounded, color: theme.colorScheme.primary.withValues(alpha: 0.8), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.username!,
                                          style: TextStyle(color: theme.colorScheme.primary.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.mail_outline_rounded, color: Colors.white.withValues(alpha: 0.4), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          user.email,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (user.specialty != null && user.specialty!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        user.specialty!,
                                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            
                            // Verification badge + arrow
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      const Text('REVIEW', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.4), size: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
