import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../users/data/users_repository.dart';
import '../../../stories/data/stories_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/story_model.dart';

final pendingProfilesProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(usersRepositoryProvider).getUsers().map(
        (users) => users.where((u) => u.appliedForVerification && !u.isVerified).toList(),
      );
});

final pendingStoriesProvider = StreamProvider<List<StoryModel>>((ref) {
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
          title: const Text('Verification Hub'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3.0,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            tabs: const [
              Tab(icon: Icon(Icons.person_outline), text: 'Profiles'),
              Tab(icon: Icon(Icons.article_outlined), text: 'Stories'),
            ],
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

    return profilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      data: (profiles) {
        if (profiles.isEmpty) {
          return const Center(
            child: Text(
              'No pending profiles.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final user = profiles[index];
            return Card(
              elevation: 4,
              color: const Color(0xFF0F0F0F),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: ThemePalette.goldenDark.accentPrimary.withAlpha(50), width: 1.0),
              ),
              child: InkWell(
                onTap: () {
                  context.push(AppRoutes.userDetail(user.userId, mode: 'verify'));
                },
                borderRadius: BorderRadius.circular(16),
                hoverColor: ThemePalette.goldenDark.accentPrimary.withAlpha(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ThemePalette.goldenDark.accentPrimary.withAlpha(40),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: user.profilePicture == null || user.profilePicture!.isEmpty 
                            ? Icon(Icons.person, color: ThemePalette.goldenDark.accentPrimary) 
                            : null,
                      ),
                    ),
                    title: Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.username != null)
                          Text('@${user.username}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        Text(user.email, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: ThemePalette.goldenDark.accentPrimary, size: 16),
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

    return storiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      data: (stories) {
        if (stories.isEmpty) {
          return const Center(
            child: Text(
              'No pending stories.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            final hasImage = story.mainImage.isNotEmpty;

            return Card(
              elevation: 4,
              color: const Color(0xFF0F0F0F),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: ThemePalette.goldenDark.accentPrimary.withAlpha(50), width: 1.0),
              ),
              child: InkWell(
                onTap: () {
                  context.push(AppRoutes.storyDetail(story.storyId, mode: 'verify'));
                },
                borderRadius: BorderRadius.circular(16),
                hoverColor: ThemePalette.goldenDark.accentPrimary.withAlpha(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: hasImage
                          ? Image.network(story.mainImage, width: 60, height: 60, fit: BoxFit.cover)
                          : Container(
                              width: 60,
                              height: 60,
                              color: const Color(0xFF1E1E1E),
                              child: Icon(Icons.article, color: ThemePalette.goldenDark.accentPrimary),
                            ),
                    ),
                    title: Text(
                      story.heading,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Author ID: ${story.authorId}',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: ThemePalette.goldenDark.accentPrimary, size: 16),
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
