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
                    'Overview',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Summary Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _SummaryCard(
                        title: 'Total Users',
                        value: '${stats['totalUsers']}',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _SummaryCard(
                        title: 'Pending Verifications',
                        value: '${stats['pendingProfiles']! + stats['pendingStories']!}',
                        icon: Icons.verified,
                        color: Colors.orange,
                      ),
                      _SummaryCard(
                        title: 'Active Reports',
                        value: '${stats['activeReports']}',
                        icon: Icons.gavel,
                        color: Colors.red,
                      ),
                      _SummaryCard(
                        title: 'Active Chats',
                        value: '${stats['activeSupportChats']}',
                        icon: Icons.support_agent,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  Text(
                    'Management Hubs',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
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
                            subtitle: 'Manage platform users and roles',
                            icon: Icons.manage_accounts,
                            onTap: () => context.push(AppRoutes.users),
                          ),
                          _ActionCard(
                            title: 'Verification',
                            subtitle: 'Review pending profiles & stories',
                            icon: Icons.verified_user,
                            onTap: () => context.push(AppRoutes.verification),
                            badgeCount: stats['pendingProfiles']! + stats['pendingStories']!,
                          ),
                          _ActionCard(
                            title: 'Support',
                            subtitle: 'Respond to user inquiries',
                            icon: Icons.headset_mic,
                            onTap: () => context.push(AppRoutes.supportChats),
                            badgeCount: stats['unreadSupportChats'],
                          ),
                          _ActionCard(
                            title: 'Moderation',
                            subtitle: 'Review reported content',
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDestructive ? Colors.red.withAlpha(20) : theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 28,
                  color: isDestructive ? Colors.red : theme.colorScheme.primary,
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDestructive ? Colors.red : theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurfaceVariant, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
