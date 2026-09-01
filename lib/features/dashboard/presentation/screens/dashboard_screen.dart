import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../users/data/users_repository.dart';
import '../../../stories/data/stories_repository.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../../support_chats/data/support_chats_repository.dart';

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final usersRepo = ref.watch(usersRepositoryProvider);
  final storiesRepo = ref.watch(storiesRepositoryProvider);
  final moderationRepo = ref.watch(moderationRepositoryProvider);
  final supportChatsRepo = ref.watch(supportChatsRepositoryProvider);

  final totalUsersCount = await usersRepo.getTotalUsersCount();
  final pendingProfiles = (await usersRepo.getUsers()).where((u) => u.appliedForVerification && !u.isVerified).length;
  
  final storiesResult = await storiesRepo.getPendingStories();
  final reportsResult = await moderationRepo.getPendingReports();
  
  final chatsResult = await supportChatsRepo.getSupportChatsStream().first;
  int unreadSupportChats = 0;
  for (var chat in chatsResult) {
    if ((chat.unreadCount['admin'] ?? 0) > 0) unreadSupportChats++;
  }
  
  return {
    'totalUsers': totalUsersCount,
    'pendingProfiles': pendingProfiles,
    'pendingStories': storiesResult.length,
    'activeReports': reportsResult.length,
    'activeSupportChats': chatsResult.length,
    'unreadSupportChats': unreadSupportChats,
  };
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: theme.colorScheme.error))),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardStatsProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Management Hubs',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a tool below to begin managing the platform.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        crossAxisCount: constraints.maxWidth > 800 ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: constraints.maxWidth > 800 ? 3 : 2.5,
                        children: [
                          _ActionCard(
                            title: 'Users',
                            subtitle: '${stats['totalUsers']} Total Users\nManage platform users and roles',
                            icon: Icons.manage_accounts,
                            onTap: () => context.push(AppRoutes.users),
                          ),
                          _ActionCard(
                            title: 'Verification',
                            subtitle: '${stats['pendingProfiles']} Profiles, ${stats['pendingStories']} Stories Pending\nReview pending profiles & stories',
                            icon: Icons.verified_user,
                            onTap: () => context.push(AppRoutes.verification),
                            badgeCount: stats['pendingProfiles']! + stats['pendingStories']!,
                          ),
                          _ActionCard(
                            title: 'Support',
                            subtitle: '${stats['activeSupportChats']} Active Chats\nRespond to user inquiries',
                            icon: Icons.headset_mic,
                            onTap: () => context.push(AppRoutes.supportChats),
                            badgeCount: stats['unreadSupportChats'],
                          ),
                          _ActionCard(
                            title: 'Moderation',
                            subtitle: '${stats['activeReports']} Active Reports\nReview reported content',
                            icon: Icons.gavel,
                            onTap: () => context.push(AppRoutes.moderation),
                            badgeCount: stats['activeReports'],
                            isDestructive: true,
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isDestructive;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badgeCount,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(20), 
          width: 1
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: isDestructive 
                    ? Colors.redAccent.withAlpha(30) 
                    : theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 32,
                  color: isDestructive ? Colors.redAccent : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDestructive ? Colors.redAccent : theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
